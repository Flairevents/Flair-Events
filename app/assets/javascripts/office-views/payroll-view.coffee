class PayrollView extends View

  constructor: (@db, @viewport) ->
    super(@viewport)

    @shownSubview = 'timesheet'

    @statusDropdown   = @viewport.find('.filter-bar select[name="status"]')
    @taxWeekDropdown  = @viewport.find('.filter-bar select[name="tax_week_id"]')
    @taxYearDropdown  = @viewport.find('.filter-bar select[name="tax_year_id"]')
    @eventDropdown    = @viewport.find('.filter-bar select[name="event_id"]')
    @reportDropdown   = @viewport.find('.filter-bar select[name="time_clock_report_id"]')
    @jobDropdown      = @viewport.find('.filter-bar select[name="job_id"]')
    @typeDropdown     = @viewport.find('.filter-bar select[name="type"]')
    @asgnmtDropdown   = @viewport.find('.filter-bar select[name="assignment_id"]')
    @asgnJobDropdown  = @viewport.find('.filter-bar select[name="assignment_job_id"]')
    @asgnLocDropdown  = @viewport.find('.filter-bar select[name="assignment_location_id"]')
    @asgnShftDropdown = @viewport.find('.filter-bar select[name="assignment_shift_id"]')
    @asgnDateDropdown = @viewport.find('.filter-bar select[name="assignment_date"]')
    @searchInput      = @viewport.find('.filter-bar input[name="search"]')

    ################################
    ##### Timesheet View Setup #####
    ################################

    hours = (instance, td, row, col, prop, value, cellProperties) =>
      time_start = instance.getDataAtCell(row, @timesheetColumnIndex['time_start'])
      time_end = instance.getDataAtCell(row, @timesheetColumnIndex['time_end'])
      gig_assignment_id = instance.getSourceDataAtCell(row, @timesheetColumnIndex['gig_assignment_id'])
      paid_breaks = @db.findId('events', @db.findId('gigs', @db.findId('gig_assignments', gig_assignment_id).gig_id).event_id).paid_breaks
      break_string = instance.getDataAtCell(row, @timesheetColumnIndex['break_minutes'])
      break_minutes = if break_string != '' then parseInt(break_string) else 0
      if time_start? && time_end?
        td.innerText = @getTimesheetEntryTotalHours(time_start, time_end, break_minutes, paid_breaks)
      else
        td.innerText = ''
      td.style.textAlign = 'right'
      td.className = 'htDimmed'
      td

    #'props' passed directly to handsontable in the 'columns' property.
    #Rest of the properties can be custom.
    @timesheet_columns = [
      {name: 'invoiced',          heading: 'Inv',        bulk: false, blank: null, width: 30, props: {type: 'checkbox', className: 'td-checkbox'}},
      {
        name: 'prospect_name',    heading: 'Name',       bulk: false, blank: '',   width: 200, props: {readOnly: true, renderer: 'html'},
        fn: (tse) =>
          name = prospectName(@db.findId('prospects', @db.findId('gigs', @db.findId('gig_assignments', tse.gig_assignment_id).gig_id).prospect_id))
          if tse.invoiced
            "<span class='hilite'>#{name}</span>"
          else
            name
      },
      {name: 'time_start',        heading: 'Start',      bulk: true,  blank: '', width: 45,  props: {type: 'time', timeFormat: 'H:mm', correctFormat: true, allowInvalid: false}},
      {name: 'time_end',          heading: 'End',        bulk: true,  blank: '', width: 45,  props: {type: 'time', timeFormat: 'H:mm', correctFormat: true, allowInvalid: false}},
      {name: 'break_minutes',     heading: 'Break',      bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0'}},
      {name: "hours",             heading: "Total",      bulk: false, blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', readOnly: true, renderer: hours}},
      {name: 'rating',            heading: 'Rating',     bulk: true,  blank: 0,  width: 50,  props: {type: 'dropdown', source: ['', 5,4,3,2,1], allowInvalid: false}},
      {name: 'assignment',        heading: 'Assignment', bulk: false, blank: '', width: 300, props: {readOnly: true}, fn: (tse) => printAssignment(@db.findId('assignments', @db.findId('gig_assignments', tse.gig_assignment_id).assignment_id))},
      {name: 'notes',             heading: 'Notes',      bulk: true,  blank: '', width: 300, props: {}},
      {name: 'event_name',        heading: 'Event',      bulk: false, blank: '', width: 175, props: {readOnly: true}, fn: (tse) => @db.findId('events', @db.findId('gigs', @db.findId('gig_assignments', tse.gig_assignment_id).gig_id).event_id).name },
      {name: 'gig_assignment_id', hidden: true},
      {name: 'tax_week_id',       hidden: true},
      {name: 'status',            hidden: true},
      {name: 'id',                hidden: true},
    ]

    @timesheetColumnIndex = {}
    n = 0
    for c in @timesheet_columns
      @timesheetColumnIndex[c.name]=n++

    tsi_displayed = @timesheet_columns.filter((col) -> !col.hidden)
    @timesheetColumnIndexDisplayed = {}
    n=0
    for i in tsi_displayed
      @timesheetColumnIndexDisplayed[i.name]=n++

    #Track if we are saving due to requested save (autosaving=t), or a database change (autosaving=f)
    @timesheetAutosaving = false

    contextMenu = {
      callback: (key, options) =>
        if (key == 'delete')
          ids = []
          for cellCoords in options
            for row in [cellCoords.start.row..cellCoords.end.row]
              ids.push(@timesheetGrid.handsontable('getInstance').getDataAtCell(row, @timesheetColumnIndex['id']))
          if ids.length > 0
            message = "Are you sure you want to delete the selected timesheets? This will also delete their corresponding Gig Assignments."
            bootbox.confirm(message, (result) =>
              if result
                ServerProxy.saveChanges('/office/delete_timesheet_entries', {ids: ids}, Actor(
                  requestSuccess: =>
                    @redraw()), @db))
      items: {
        delete: {name: 'Delete'}
      }
    }

    @timesheetColumnProps      = (i.props   for i in tsi_displayed)
    @timesheetGrid = @viewport.find('.timesheet-grid').handsontable({
      startRows:           0,
      startCols:           @timesheetColumnProps.length,
      colHeaders:          (i.heading for i in tsi_displayed),
      rowHeaders:          true,
      columns:             @timesheetColumnProps,
      colWidths:           (i.width   for i in tsi_displayed),
      fixedColumnsLeft:    1,
      currentRowClassName: 'currentRow',
      stretchH:            'all',
      contextMenu:         contextMenu,
    })

    that = @
    @timesheetGrid.handsontable('getInstance').updateSettings({
      cells: (sourceRow, sourceCol, prop) ->
        cellProperties = {}

        if sourceCol == that.timesheetColumnIndex['invoiced']
          cellProperties.readOnly = false
        else if (that.statusDropdown.val() == 'SUBMITTED') && !(that.viewport.find('.command-bar #allowTimesheetEdit').prop('checked'))
          cellProperties.readOnly = true
        else
          cellProperties.readOnly = (that.timesheet_columns[sourceCol].props.readOnly == true)
        return cellProperties
    })

    @timesheetGrid.handsontable('getInstance').addHook('afterChange', (changes, source) =>
      @saveTimesheetChanges(changes, source))

    @timesheetGrid.find('table').addClass('zebraStyle')

    bulk_tsi = tsi_displayed.filter((col) -> col.bulk)
    bulk_invoice_column = {name: 'invoiced', heading: 'Inv', props: {type: 'dropdown', source: ['', '☑', '☐'] }}
    bulk_tsi.unshift(bulk_invoice_column)

    @timesheetBulkColumnIndex = {}
    n = 0
    for i in bulk_tsi
      @timesheetBulkColumnIndex[i.name]=n++

    @timesheetBulkUpdater = @viewport.find('#bulk-update-timesheet').handsontable({
      startRows:  1,
      startCols:  11,
      colHeaders: (i.heading for i in bulk_tsi),
      columns:    (i.props   for i in bulk_tsi),
      colWidths:  (i.width   for i in bulk_tsi)
    })
    @timesheetBulkUpdater.handsontable('getInstance').setCellMeta(0, 0, 'className', 'td-htCheckbox');

    bulk_tsii = [bulk_invoice_column]

    @timesheetInvoiceBulkColumnIndex = {}
    n = 0
    for i in bulk_tsii
      @timesheetInvoiceBulkColumnIndex[i.name]=n++

    @timesheetInvoiceBulkUpdater = @viewport.find('#bulk-update-timesheet-invoice').handsontable({
      startRows:  1,
      startCols:  11,
      colHeaders: (i.heading for i in bulk_tsii),
      columns:    (i.props   for i in bulk_tsii),
      colWidths:  (i.width   for i in bulk_tsii)
    })
    @timesheetInvoiceBulkUpdater.handsontable('getInstance').setCellMeta(0, 0, 'className', 'td-htCheckbox');

    ##############################
    ##### Payroll View Setup #####
    ##############################

    hours = (instance, td, row, col, prop, value, cellProperties) =>
      # Only grey out the background if we're NOT in readOnly mode
      colIsNotEditable = (!@viewport.find('.command-bar #allowPayrollEdit').prop('checked') && @statusDropdown.val() == 'SUBMITTED') || !@isEditableField(@payroll_columns[col])
      if !colIsNotEditable && cellProperties.readOnly
        td.className = 'invalidDay'
        td.className = 'htDimmed'
      td.innerText = value
      td

    totalHours = (instance, td, row, col, prop, value, cellProperties) =>
      td.innerText =
        Number(instance.getDataAtCell(row, @payrollColumnIndex['monday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['tuesday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['wednesday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['thursday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['friday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['saturday'])) +
        Number(instance.getDataAtCell(row, @payrollColumnIndex['sunday']))
      td.style.textAlign = 'right'
      td.className = 'htDimmed'
      td

    #'props' passed directly to handsontable in the 'columns' property.
    #Rest of the properties can be custom.
    @payroll_columns = [
      {name: "prospect_name",  heading: "Name",      bulk: false, blank: '', width: 200, props: {readOnly: true}, fn: (pw) => prospectName(@db.findId('prospects', pw.prospect_id)) },
      {name: "monday",         heading: "M",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "tuesday",        heading: "T",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "wednesday",      heading: "W",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "thursday",       heading: "T",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "friday",         heading: "F",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "saturday",       heading: "S",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "sunday",         heading: "S",         bulk: true,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', renderer: hours}},
      {name: "total",          heading: "Total",     bulk: false,  blank: 0,  width: 45,  props: {type: 'numeric', format: '0[.][0]0', readOnly: true, renderer: totalHours}},
      {name: "rate",           heading: "Rate",      bulk: true,  blank: 0,  width: 60,  props: {type: 'numeric', numericFormat: { pattern: '$0.00', culture: 'en-GB'}}},
      {name: "deduction",      heading: "Deduct",    bulk: true,  blank: 0,  width: 60,  props: {type: 'numeric', numericFormat: { pattern: '$0.00', culture: 'en-GB'}}}
      {name: "allowance",      heading: "Allow",     bulk: true,  blank: 0,  width: 60,  props: {type: 'numeric', numericFormat: { pattern: '$0.00', culture: 'en-GB'}}}
      {name: "job_name",       heading: "Job",       bulk: false, blank: '', width: 75,  props: {}, fn: (pw) => if typeof (job = @db.findId('jobs', pw.job_id)) isnt 'undefined' then job.name  else '' },
      {name: "type",           heading: "Type",      bulk: false, blank: '', width: 70,  props: {readOnly: true}},
      {name: "event_name",     heading: "Event",     bulk: false, blank: '', width: 175, props: {readOnly: true}, fn: (pw) => (if pw.event_id? then @db.findId('events', pw.event_id).name else '') },
      {name: "prospect_id",    hidden: true},
      {name: "event_id",       hidden: true}
      {name: 'job_id',         hidden: true}
      {name: "status",         hidden: true},
      {name: "id",             hidden: true},
    ]

    @payrollColumnIndex = {}
    n = 0
    for c in @payroll_columns
      @payrollColumnIndex[c.name]=n++

    pwi_displayed = @payroll_columns.filter((col) -> !col.hidden)
    @payrollColumnIndexDisplayed = {}
    n=0
    for i in pwi_displayed
      @payrollColumnIndexDisplayed[i.name]=n++

    #Track if we are saving due to requested save (autosaving=t), or a database change (autosaving=f)
    @payrollAutosaving = false

    @activeDays = {}
    @jobs = {}

    contextMenu = {
      callback: (key, options) =>
        if (key == 'addPayrollEntry')
          ids = []
          for cellCoords in options
            for row in [cellCoords.start.row..cellCoords.end.row]
              ids.push(@payrollGrid.handsontable('getInstance').getDataAtCell(row, @payrollColumnIndex['id']))
          if ids.length > 0
            ServerProxy.saveChanges("/office/create_pay_weeks_from_pay_weeks", { ids: ids, tax_week_id: @getCurrentTaxWeekId(), status: @statusDropdown.val() }, null, @db)
        if (key == 'delete')
          ids = []
          for cellCoords in options
            for row in [cellCoords.start.row..cellCoords.end.row]
              ids.push(@payrollGrid.handsontable('getInstance').getDataAtCell(row, @payrollColumnIndex['id']))
          if ids.length > 0
            ServerProxy.saveChanges('/office/delete_pay_weeks', {ids: ids}, Actor(
              requestSuccess: =>
                @redraw()), @db)
      items: {
        addPayrollEntry: { name: 'Add Payroll Entry'}
        delete: {name: 'Delete'}
      }
    }

    @payrollColumnProps      = (i.props   for i in pwi_displayed)
    @payrollGrid = @viewport.find('.payroll-grid').handsontable({
      startRows:           0,
      startCols:           @payrollColumnProps.length,
      colHeaders:          (i.heading for i in pwi_displayed),
      rowHeaders:          true,
      columns:             @payrollColumnProps,
      colWidths:           (i.width   for i in pwi_displayed),
      fixedColumnsLeft:    1,
      currentRowClassName: 'currentRow',
      stretchH:            'all',
      contextMenu:         contextMenu,
    })

    that = @
    @payrollGrid.handsontable('getInstance').updateSettings({
      cells: (sourceRow, sourceCol, prop) ->
        cellProperties = {}

        if (that.statusDropdown.val() == 'SUBMITTED') && !(that.viewport.find('.command-bar #allowPayrollEdit').prop('checked'))
          cellProperties.readOnly = true
        else if (this.instance.getSourceDataAtCell(sourceRow, that.payrollColumnIndex['type']) == 'AUTO')
          unless (sourceCol == that.payrollColumnIndex['allowance']) || (sourceCol == that.payrollColumnIndex['deduction'])
            cellProperties.readOnly = true
        else if sourceCol == that.payrollColumnIndex['rate']
          job_id = this.instance.getSourceDataAtCell(sourceRow, that.payrollColumnIndex['job_id'])
          cellProperties.readOnly = true if job_id?
        else if that.payrollColumnIndex['monday'] <= sourceCol && sourceCol <= that.payrollColumnIndex['sunday']
          event_id =  this.instance.getSourceDataAtCell(sourceRow, that.payrollColumnIndex['event_id'])
          cellProperties.readOnly = !(that.activeDays[event_id][sourceCol] == true) if event_id? && that.activeDays[event_id]?
        else if sourceCol == that.payrollColumnIndex['job_name']
          event_id =  this.instance.getSourceDataAtCell(sourceRow, that.payrollColumnIndex['event_id'])
          if event_id && that.jobs[event_id]? && that.jobs[event_id].length > 0
            cellProperties.type = 'dropdown'
            cellProperties.source = that.jobs[event_id]
          else
            cellProperties.readOnly = true
        else
          cellProperties.readOnly = (that.payroll_columns[sourceCol].props.readOnly == true)
        return cellProperties
    })

    @payrollGrid.handsontable('getInstance').addHook('afterChange', (changes, source) =>
      @savePayWeekChanges(changes, source))

    @payrollGrid.find('table').addClass('zebraStyle')

    bulk_pwi = pwi_displayed.filter((col) -> col.bulk)

    @payrollBulkColumnIndex = {}
    n = 0
    for i in bulk_pwi
      @payrollBulkColumnIndex[i.name]=n++

    @payrollBulkUpdater = @viewport.find('#bulk-update-payroll').handsontable({
      width:      500,
      height:     50,
      startRows:  1,
      startCols:  11,
      colHeaders: (i.heading for i in bulk_pwi),
      columns:    (i.props   for i in bulk_pwi),
      colWidths:  (i.width   for i in bulk_pwi)
    })

    #########################
    ##### General Setup #####
    #########################

    @commandBar = new CommandBar(@viewport, @)
    @filterBar  = new FilterBar(@viewport.find('.filter-bar'), @)

    @db.onUpdate('events', =>
      @updateTaxYearOptions())

    @db.onUpdate('timesheet_entries', =>
      unless @timesheetAutosaving
        @updateTaxYearOptions()
        @redraw()
      @timesheetAutosaving = false)

    @db.onUpdate('pay_weeks', =>
      unless @payrollAutosaving
        @updateTaxYearOptions()
        @redraw()
      @payrollAutosaving = false)

    @db.onUpdate(['assignments', 'jobs', 'locations', 'shifts'], =>
      @updateEventFilters())

    @addRemoveEmployeesDialog = @viewport.find('.multi-assigner')
    @assigner = new MultiAssigner(@addRemoveEmployeesDialog.find('.modal-body'), @)

    @reportDownloader = new PayrollReportDownloader(@, @db, @filterBar)
    @reportDialog = new ReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new ReportMenu(@viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    # Hide/show buttons based on the current status
    @initializeFilters()

    # We don't use the standard "filter" routine, because we want to get fancy with the filters (doing more than filtering)
    # That means setting up an event handler for each filter.
    @statusDropdown.change  => @statusChange()
    @taxYearDropdown.change => @taxYearChange()
    @taxWeekDropdown.change => @taxWeekChange()
    @eventDropdown.change   => @eventChange()
    @viewport.find('.command-bar #allowPayrollEdit').change =>
      @showHideEditingElements()
      @redraw()
    @viewport.find('.command-bar #allowTimesheetEdit').change =>
      @showHideEditingElements()
      @redraw()
    @reportDropdown.change =>
      @timeClockReportChange()
      @redraw()
    @jobDropdown.change      => @redraw()
    @typeDropdown.change     => @redraw()
    @asgnmtDropdown.change   => @redraw()
    @asgnJobDropdown.change  => @redraw()
    @asgnLocDropdown.change  => @redraw()
    @asgnShftDropdown.change => @redraw()
    @asgnDateDropdown.change => @redraw()
    @searchInput.change =>
      @redraw()
    @searchInput.keypress((event) =>
      if event.which == 13 # apply filter when 'enter' pressed
        @redraw())

    @viewport.find('.payroll-view-only').hide()
    @viewport.find('.timesheet-view-only').show()

    that = @
    @viewport.find('#uploadScannedTimesheet').on('change', (e) ->
      if $(this).val != ''
        data={event_id: that.getCurrentEventId(), tax_week_id: that.getCurrentTaxWeekId() }
        for file, i in this.files
          data['scan'+i] = file
        ServerProxy.saveFormData("/office/upload_scanned_timesheets/", data, Actor(
          requestSuccess: =>
            # Reset the value of the input field, otherwise the change event won't fire if re-uploading a file of the same name
            $(this).val('')
        ), that.db))

  draw: =>
    if @shownSubview == 'payroll'
      @drawSubview(@payrollBulkUpdater, 'pay_weeks', @payroll_columns, @payrollGrid, payweekSort)
    else
      @drawSubview(@timesheetBulkUpdater, 'timesheet_entries', @timesheet_columns, @timesheetGrid, timesheetEntrySort)

  drawSubview: (bulkUpdater, table, columns, grid, sortFunction) =>
    bulkUpdater.handsontable('render')
    if @dropDownValueBlank(@taxWeekDropdown)
      records = []
    else
      records = @db.queryAll(table, @getFilters(), sortFunction)

    # Update Summary
    staff = {}
    total_hours = 0
    total_breaks = 0
    net_hours = 0
    paid_hours = 0

    for record in records
      if table == 'timesheet_entries'
        paid_hours   += @getTimesheetEntryTotalHours( record.time_start, record.time_end, record.break_minutes, @db.findId('events', @db.findId('gigs', @db.findId('gig_assignments', record.gig_assignment_id).gig_id).event_id).paid_breaks)
        total_hours  += @getTimesheetEntryLoggedHours(record.time_start, record.time_end)
        net_hours    += @getTimesheetEntryNetHours(   record.time_start, record.time_end, record.break_minutes)
        total_breaks += record.break_minutes if record.break_minutes
        staff[@db.findId('prospects', @db.findId('gigs', @db.findId('gig_assignments', record.gig_assignment_id).gig_id).prospect_id).id] = true
      if table == 'pay_weeks'
        total_hours += (Number(record.monday) + Number(record.tuesday) + Number(record.wednesday) + Number(record.thursday) + Number(record.friday) + Number(record.saturday) + Number(record.sunday))
        staff[@db.findId('prospects', record.prospect_id).id] = true
        @viewport.find('#payroll-summary-total-staff').text(Object.keys(staff).length)
        @viewport.find('#payroll-summary-total-hours').text(Math.round(total_hours*100) / 100)

    if table == 'timesheet_entries'
      if records.length > 0
        @viewport.find('#timesheet-summary-total-staff').text(Object.keys(staff).length)
        @viewport.find('#timesheet-summary-paid-hours').text(Math.round(paid_hours*100) / 100)
        @viewport.find('#timesheet-summary-total-hours').text(Math.round(total_hours*100) / 100)
        @viewport.find('#timesheet-summary-net-hours').text(Math.round(net_hours*100) / 100)
        @viewport.find('#timesheet-summary-total-breaks').text(Math.ceil((minToHrs(total_breaks))*100) / 100)
      else
        @viewport.find('#timesheet-summary-total-staff').text('')
        @viewport.find('#timesheet-summary-paid-hours').text('')
        @viewport.find('#timesheet-summary-total-hours').text('')
        @viewport.find('#timesheet-summary-net-hours').text('')
        @viewport.find('#timesheet-summary-total-breaks').text('')

    if table == 'pay_weeks'
      if records.length > 0
        @viewport.find('#payroll-summary-total-staff').text(Object.keys(staff).length)
        @viewport.find('#payroll-summary-total-hours').text(Math.round(total_hours*100) / 100)
      else
        @viewport.find('#payroll-summary-total-staff').text('')
        @viewport.find('#payroll-summary-total-hours').text('')

    # Load records into handsontable
    data = records.map((pw) =>
      row = []
      for i in columns
        if typeof i.fn isnt 'undefined'
          row.push i.fn(pw)
        else
          row.push pw[i.name]
      row)
    grid.handsontable('loadData', data)

  getTimesheetEntryTotalHours: (time_start, time_end, break_minutes, paid_breaks) =>
    break_minutes = (if !paid_breaks && break_minutes then break_minutes else 0)
    if time_start? && time_end?
      split = time_start.split(':')
      datetimeStart = new Date(1970, 1, 1, parseInt(split[0], 10), parseInt(split[1], 10))
      split = time_end.split(':')
      datetimeEnd = new Date(1970, 1, (if padDigits(time_end, 5) < padDigits(time_start, 5) then 2 else 1), parseInt(split[0], 10), parseInt(split[1], 10))
      Math.ceil((minToHrs(msToMin(datetimeEnd - datetimeStart)-break_minutes))*100) / 100;
    else
      0

  getTimesheetEntryLoggedHours: (time_start, time_end) =>
    if time_start? && time_end?
      split = time_start.split(':')
      datetimeStart = new Date(1970, 1, 1, parseInt(split[0], 10), parseInt(split[1], 10))
      split = time_end.split(':')
      datetimeEnd = new Date(1970, 1, (if padDigits(time_end, 5) < padDigits(time_start, 5) then 2 else 1), parseInt(split[0], 10), parseInt(split[1], 10))
      Math.ceil(msToHrs(datetimeEnd - datetimeStart)*100) / 100;
    else
      0

  getTimesheetEntryNetHours: (time_start, time_end, break_minutes) =>
    break_minutes = if break_minutes then break_minutes else 0
    if time_start? && time_end?
      split = time_start.split(':')
      datetimeStart = new Date(1970, 1, 1, parseInt(split[0], 10), parseInt(split[1], 10))
      split = time_end.split(':')
      datetimeEnd = new Date(1970, 1, (if padDigits(time_end, 5) < padDigits(time_start, 5) then 2 else 1), parseInt(split[0], 10), parseInt(split[1], 10))
      Math.ceil((minToHrs(msToMin(datetimeEnd - datetimeStart)-break_minutes))*100) / 100;
    else
      0

  getFilters: =>
    filters = @filterBar.selectedFilters()
    if @shownSubview == 'timesheet'
      assignment_filter = {}
      assignment_filter['assignment_id'] = parseInt(filters.assignment_id, 10)           if filters.assignment_id?
      assignment_filter['job_id']        = parseInt(filters.assignment_job_id, 10)       if filters.assignment_job_id?
      assignment_filter['location_id']   = parseInt(filters.assignment_location_id, 10)  if filters.assignment_location_id?
      assignment_filter['shift_id']      = parseInt(filters.assignment_shift_id, 10)     if filters.assignment_shift_id?
      assignment_filter['date']          = new Date(Date.parse(filters.assignment_date)) if filters.assignment_date?
      filters.assignment = assignment_filter unless Object.keys(assignment_filter).length == 0
      delete filters.job_id
      delete filters.type
    delete filters.assignment_id
    delete filters.assignment_job_id
    delete filters.assignment_location_id
    delete filters.assignment_shift_id
    delete filters.assignment_date
    filters

  bulkUpdatePayroll: ->
    @bulkUpdate(@payrollBulkUpdater, @payrollGrid, @payrollBulkColumnIndex, @payrollColumnIndex)
  bulkUpdateTimesheet: ->
    @bulkUpdate(@timesheetBulkUpdater, @timesheetGrid, @timesheetBulkColumnIndex, @timesheetColumnIndex)
  bulkUpdateTimesheetInvoice: ->
    @bulkUpdate(@timesheetInvoiceBulkUpdater, @timesheetGrid, @timesheetInvoiceBulkColumnIndex, @timesheetColumnIndex)
  bulkUpdate: (bulkUpdater, grid, bulkColumnIndex, gridColumnIndex) ->
    bulkTbl = bulkUpdater.handsontable('getInstance')
    mainTbl = grid.handsontable('getInstance')
    for key of bulkColumnIndex
      value = bulkTbl.getDataAtCell(0, bulkColumnIndex[key])
      if value? && value != ''
        newValues = []
        for rowIndex in [0...mainTbl.countRows()]
          value = (value == '☑') if bulkTbl.getCellMeta(rowIndex, gridColumnIndex[key]).className == 'td-htCheckbox'
          newValues.push([value])
        mainTbl.populateFromArray(0, gridColumnIndex[key], newValues)
    bulkUpdater.handsontable('clear')
    bulkTbl.deselectCell()

  importTimesheetsForEvent: =>
    ServerProxy.saveChanges('/office/create_timesheet_entries_for_event/', {event_id: @eventDropdown.val(), tax_week_id: @getCurrentTaxWeekId(), status: @statusDropdown.val() }, Actor(
      requestSuccess: =>
        @toggleSubview() if @shownSubview == 'payroll'
    ), @db)

  importPayrollForEvent: =>
    unassigned = @getPayrollAssignments(@getCurrentEventId()).unassigned.map((p) -> p[1])
    if unassigned.length > 1
      ServerProxy.saveChanges('/office/create_pay_weeks_for_event/', {id: @eventDropdown.val(), tax_week_id: @getCurrentTaxWeekId(), status: @statusDropdown.val(), prospect_ids: unassigned }, Actor(
        requestSuccess: =>
          @toggleSubview() if @shownSubview == 'timesheets'
      ), @db)

  addRemoveEmployees: (event_id) =>
    employeeInfo = @getPayrollAssignments(@getCurrentEventId())
    @assigner.choices(employeeInfo.choices.sort(@sortAddRemoveEmployeesArray))
    @assigner.selected(employeeInfo.selected.sort(@sortAddRemoveEmployeesArray))
    @assigner.draw()
    @addRemoveEmployeesDialog.modal('show')

  saveAndCloseAssigner: =>
    data = @assigner.getChanges()

    if data.added.length > 0 || data.removed.length > 0
      ServerProxy.saveChanges('/office/add_remove_pay_weeks', {
        event_id: @getCurrentEventId(),
        tax_week_id: @getCurrentTaxWeekId(),
        status: @statusDropdown.val(),
        prospects_add: data.added,
        prospects_remove: data.removed },
        Actor(
          requestSuccess: =>
            @redraw()
            @addRemoveEmployeesDialog.modal('hide')
        ),
        @db)
    else
      @addRemoveEmployeesDialog.modal('hide')

  # Return arrays in format: [["prospect name", prospect_id], ["prospect name", prospect_id]...]
  getPayrollAssignments: (event_id) =>
    choices = {}
    selected = {}
    if event_id?
      for gig in @db.queryAll('gigs', {event_id: event_id, status: 'Active'})
        prospect = @db.findId('prospects', gig.prospect_id)
        choices[prospect.id] = prospectName(prospect)
    else
      for prospect in @db.queryAll('prospects', {status: 'EMPLOYEE'})
        choices[prospect.id] = prospectName(prospect)
    for row in @payrollGrid.handsontable('getInstance').getSourceData()
      choices[row[@payrollColumnIndex['prospect_id']]] = row[@payrollColumnIndex['prospect_name']]
      selected[row[@payrollColumnIndex['prospect_id']]] = row[@payrollColumnIndex['prospect_name']]
    final_choices = []
    final_choice_ids = []
    for id, name of choices
      final_choices.push([name, parseInt(id)])
      final_choice_ids.push(parseInt(id))
    final_selected = []
    final_selected_ids = []
    for id, name of selected
      final_selected.push([name, parseInt(id)])
      final_selected_ids.push(parseInt(id))
    final_unassigned = []
    for id in final_choice_ids.filter((choice_id) -> final_selected_ids.indexOf(choice_id) < 0)
      prospect = @db.findId('prospects', id)
      final_unassigned.push([prospectName(prospect), id])

    {choices: final_choices, selected: final_selected, unassigned: final_unassigned}

  sortAddRemoveEmployeesArray: (a,b) ->
    if a[0] < b[0] then return -1
    if a[0] > b[0] then return 1
    return 0

  initializeFilters: =>
    @statusChange()

  statusChange: =>
    @updateTaxYearOptions()
    @showHideStatusDependentElements()
    @showHideEditingElements()
    status = @statusDropdown.val()
    if status == 'PENDING' || status == 'SUBMITTED'
      @eventDropdown.val('')
    if status != 'TO_APPROVE'
      @reportDropdown.val('')
    @updateButtonSelectability()

  taxYearChange: =>
    @updateTaxWeekDropdown()

  taxWeekChange: =>
    @updateEventOptions()
    @redraw()

  eventChange: =>
    event_id = @getDropDownValue(@eventDropdown)
    $expenseMessage = @viewport.find('.expense-message')
    $minHrsMessage = @viewport.find('.min-hrs-message')
    if event_id && (event = @db.findId('events', event_id))
      message = ''
      if event.has_expenses && (event.accom_status == 'NEED' || event.accom_status == 'BOOKED')
        message = 'Has Expenses And Accomodation'
      else if event.has_expenses
        message = 'Has Expenses'
      else if (event.accom_status == 'NEED' || event.accom_status == 'BOOKED')
        message = 'Has Accomodation'
      if message == ''
        $expenseMessage.hide()
      else
        $expenseMessage.text(message).show()

      min_hrs = []
      for booking in @db.queryAll('bookings', event_id: event.id)
        if booking.minimum_hours and booking.minimum_hours != ''
          min_hrs.push booking.minimum_hours
      if min_hrs.length > 0
        $minHrsMessage.text("Min Hrs: " + min_hrs.uniqueItems().join(', ')).show()
      else
        $minHrsMessage.hide()
    else
      $expenseMessage.text('').hide()
      $minHrsMessage.hide()

    @updateButtonSelectability()
    @redraw()
    @updateEventFilters()

  timeClockReportChange: =>
    if @dropDownValueBlank(@reportDropdown) then $('#approval').hide() else $('#approval').show()
    @updateTimesheetApprovalFields()

  updateTimesheetApprovalFields: =>
    time_clock_report_id = @getDropDownValue(@reportDropdown)
    $approval = @viewport.find('#approval')
    if time_clock_report_id? && time_clock_report_id != ''
      time_clock_report = @db.findId('time_clock_reports', time_clock_report_id)
      $approval = @viewport.find('#approval')
      $approval.find('#approval-date-submitted').text(printDateTimeWithDOW(time_clock_report.date_submitted))
      $approval.find('#approval-notes').text(time_clock_report.notes)
      star_rating = ''
      for i in [0..4]
        star_rating = star_rating + if i < time_clock_report.client_rating then '★' else '☆'
      $approval.find('#approval-client-rating').text(star_rating)
      $approval.find('#approval-client-notes').text(time_clock_report.client_notes)
      $approval.find('#approved-by').text("#{time_clock_report.signed_by_name}, #{time_clock_report.signed_by_job_title}, #{time_clock_report.signed_by_company_name}")
      $signature = $approval.find('#approval-client-signature').attr('src', '/time_clock_report_signature/'+time_clock_report.id+'?force_refresh='+Math.random())
    else
      $approval.find('#approval-notes Notes').text('')
      $approval.find('#approval-client-rating').text('')
      $approval.find('#approval-client-notes').text('')
      $approval.find('#approval-approved-by').text('')
      $signature = $approval.find('#approval-client-signature').attr('src', '')

  showHideEditingElements: =>
    if @shownSubview == 'payroll'
      checked = @viewport.find('.command-bar #allowPayrollEdit').prop('checked')
    else
      checked = @viewport.find('.command-bar #allowTimesheetEdit').prop('checked')
    if @statusDropdown.val() == 'SUBMITTED'
      elements = @viewport.find(".#{@shownSubview}-view-only").find(".SUBMITTED.EDITABLE")
      if checked then elements.show() else elements.hide()
      elements = @viewport.find(".#{@shownSubview}-view-only").find(".SUBMITTED.READONLY")
      if checked then elements.hide() else elements.show()

  showHideStatusDependentElements: =>
    status = @getDropDownValue(@statusDropdown)
    for element in @viewport.find(".#{@shownSubview}-view-only").find(".NEW, .TO_APPROVE, .PENDING, .SUBMITTED")
      if $(element).hasClass(status) then $(element).show() else $(element).hide()

  updateTaxYearOptions: =>
    value = @getDropDownValue(@taxYearDropdown)
    @taxYearDropdown.empty()
    status = @statusDropdown.val()
    options = {'': ''}

    if status == 'NEW'
      for event in @db.queryAll('events', {show_in_payroll: true, active: true})
        for tax_year in @db.queryAll('tax_years', {overlaps_dates: [event.date_start, event.date_end]})
          options[printTaxYear(tax_year)] = tax_year.id
    else if status == 'TO_APPROVE'
      for tax_year in @db.queryAll('tax_years', {status_to_approve: true})
        options[printTaxYear(tax_year)] = tax_year.id
    else if status == 'PENDING'
      for tax_year in @db.queryAll('tax_years', {status_pending: true})
        options[printTaxYear(tax_year)] = tax_year.id
    else if status == 'SUBMITTED'
      for tax_year in @db.queryAll('tax_years', {status_submitted: true})
        options[printTaxYear(tax_year)] = tax_year.id

    for key in Object.keys(options).sort()
      taxYearElement = document.createElement("option")
      taxYearElement.text = key
      taxYearElement.value = options[key]
      @taxYearDropdown.append(taxYearElement)
    if @isValueInDropDown(@taxYearDropdown, value)
      @taxYearDropdown.val(value)
    @updateTaxWeekDropdown()
    @redraw()

  updateTaxWeekDropdown: =>
    options = {'': ''}
    if @dropDownValueBlank(@taxYearDropdown)
      @taxWeekDropdown.empty()
      taxWeekElement = document.createElement("option")
      taxWeekElement.text = ''
      @taxWeekDropdown.append(taxWeekElement)
      @updateEventOptions()
    else
      value = @getDropDownValue(@taxWeekDropdown)
      @taxWeekDropdown.empty()
      status = @statusDropdown.val()
      tax_year_id = parseInt(@taxYearDropdown.val())
      if status == 'NEW'
        for tax_week in @db.queryAll('tax_weeks', {current: true, tax_year_id: tax_year_id})
          options[printTaxWeek(tax_week)] = tax_week.id
      else if status == 'TO_APPROVE'
        for tax_week in @db.queryAll('tax_weeks', {status_to_approve: true, tax_year_id: tax_year_id})
          options[printTaxWeek(tax_week)] = tax_week.id
      else if status == 'PENDING'
        for tax_week in @db.queryAll('tax_weeks', {status_pending: true, tax_year_id: tax_year_id})
          options[printTaxWeek(tax_week)] = tax_week.id
      else if status == 'SUBMITTED'
        for tax_week in @db.queryAll('tax_weeks', {status_submitted: true, tax_year_id: tax_year_id})
          options[printTaxWeek(tax_week)] = tax_week.id
      for key in Object.keys(options).sort(@sortTaxWeekStrings)
        taxWeekElement = document.createElement("option")
        taxWeekElement.text = key
        taxWeekElement.value = options[key]
        @taxWeekDropdown.append(taxWeekElement)
      if @isValueInDropDown(@taxWeekDropdown, value)
        @taxWeekDropdown.val(value)
      @updateEventOptions()
      @redraw()

  sortTaxWeekStrings: (a,b) ->
    s1 = if a == '' then '' else parseInt(a.match(/^\d+/)[0])
    s2 = if b == '' then '' else parseInt(b.match(/^\d+/)[0])
    return 1 if s1 > s2
    return -1 if s1 < s2
    return 0

  updateEventOptions: =>
    options = {'': ''}
    if @dropDownValueBlank(@taxWeekDropdown)
      @eventDropdown.empty()
      eventElement = document.createElement("option")
      eventElement.text = ''
      @eventDropdown.append(eventElement)
      @eventChange()
      @jobs = {}
      @activeDays = {}
    else
      value = @getDropDownValue(@eventDropdown)
      tax_week = @db.findId('tax_weeks', @getCurrentTaxWeekId())
      @eventDropdown.empty()
      status = @statusDropdown.val()
      if status == 'NEW'
        for event in @db.queryAll('events', {show_in_payroll: true, active: true, in_tax_week: tax_week.id})
          if (@db.queryAll('pay_weeks', tax_week_id: tax_week.id, status: ['PENDING', 'SUBMITTED'], event_id: event.id).length < 0 ||
              @db.queryAll('pay_weeks', tax_week_id: tax_week.id, status: 'NEW', event_id: event.id).length > 0 ||
              @db.queryAll('pay_weeks', tax_week_id: tax_week.id, event_id: event.id).length == 0)
            options[event.name] = event.id
      else
        for event in @db.findIds('events', @db.queryAll('pay_weeks', tax_week_id: tax_week.id, status: status).map((pay_week) -> pay_week.event_id).uniqueItems())
          options[event.name] = event.id
      for key in Object.keys(options).sort()
        eventElement = document.createElement("option")
        eventElement.text = key
        eventElement.value = options[key]
        @eventDropdown.append(eventElement)

      for name, id of options
         if id != ''
           @jobs[id] = [''].concat(i.name for i in @db.queryAll('jobs', {event_id: parseInt(id)}))
           @activeDays[id] = @getActiveDaysForEvent(id)

      if @isValueInDropDown(@eventDropdown, value)
        @eventDropdown.val(value)
      else
        @eventChange()

    @updateButtonSelectability()

  updateEventFilters: ->
    event_id = @eventDropdown.val()
    tax_week = @db.findId('tax_weeks', @getCurrentTaxWeekId())
    if event_id? && event_id != ''
      # Find all assignments within the current tax week
      event_id = parseInt(event_id, 10)
      event = @db.findId('events', event_id)
      all_assignments = @db.queryAll('assignments', {event_id: event_id})
      assignments = []
      shift_ids = []
      job_ids = []
      location_ids = []
      for assignment in all_assignments
        shift = @db.findId('shifts', assignment.shift_id)
        if (tax_week.date_start <= shift.date) and (shift.date <= tax_week.date_end)
          assignments.push(assignment)
          shift_ids.push(assignment.shift_id)       unless shift_ids.indexOf(assignment.shift_id) > -1
          job_ids.push(assignment.job_id)           unless job_ids.indexOf(assignment.job_id) > -1
          location_ids.push(assignment.location_id) unless location_ids.indexOf(assignment.location_id) > -1

      options = assignments.sort(assignmentSort).map((assignment) -> [printAssignment(assignment), assignment.id])
      selectedVal = parseInt(@asgnmtDropdown.val(), 10)
      @asgnmtDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

      jobs = job_ids.map((job_id) -> @db.findId('jobs', job_id)).sort()
      options = jobs.map((job) -> [job.name, job.id])
      selectedVal = parseInt(@asgnJobDropdown.val(), 10)
      @asgnJobDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

      locations = location_ids.map((location_id) -> @db.findId('locations', location_id)).sort(locationSort)
      options = locations.map((location) -> [printLocation(location), location.id])
      selectedVal = parseInt(@asgnLocDropdown.val(), 10)
      @asgnLocDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

      shifts = shift_ids.map((shift_id) -> @db.findId('shifts', shift_id)).sort(shiftSort)
      options = shifts.map((shift) -> [printShift(shift), shift.id])
      selectedVal = parseInt(@asgnShftDropdown.val(), 10)
      @asgnShftDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

      dates = []
      date_vals = []
      for shift in shifts
        time = shift.date.getTime()
        if date_vals.indexOf(time) < 0
          dates.push(shift.date)
          date_vals.push(time)
      options = dates.map((date) -> [printDate(date), date.toString()])
      selectedVal = @asgnDateDropdown.val()
      @asgnDateDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

      time_clock_reports = @db.queryAll('time_clock_reports', {event_id: event.id, tax_week_id: tax_week.id}).sort(timeClockReportSort)
      options = time_clock_reports.map((time_clock_report) -> [printTimeClockReport(time_clock_report), time_clock_report.id])
      selectedVal = parseInt(@reportDropdown.val(), 10)
      @reportDropdown.html(buildOptions([['All', '']].concat(options), selectedVal))

    else
      @clearEventFilters()
    @filterBar.refreshWidths()

  clearEventFilters: =>
    @jobDropdown.html(buildOptions([['', ''],['None',-1]]))
    @asgnmtDropdown.empty()
    @asgnJobDropdown.empty()
    @asgnLocDropdown.empty()
    @asgnShftDropdown.empty()
    @reportDropdown.empty()

  addOptionToSelect: (text, value, selectElement) =>
    option = document.createElement("option")
    option.text = text
    option.value = value
    selectElement.append(option)

  updateButtonSelectability: =>
    @enableElement '.NEEDSEVENT', !@dropDownValueBlank(@eventDropdown)
    @enableElement '.NEEDSWEEK', !@dropDownValueBlank(@taxWeekDropdown)
    @enableElement '.NEEDSWEEK.NOEVENT', @dropDownValueBlank(@eventDropdown) && !@dropDownValueBlank(@taxWeekDropdown)

  enableElement: (elementQuery, enable) =>
    if enable
      @viewport.find(elementQuery).prop('disabled', false)
      @viewport.find(elementQuery).removeClass('disabled')
    else
      @viewport.find(elementQuery).prop('disabled', true)
      @viewport.find(elementQuery).addClass('disabled')

  dropDownValueBlank: ($element) ->
    ($element.val() == '' || $element.val() == null || $element.val() == 'undefined')

  getDropDownValue: (element) ->
    if element instanceof jQuery
      element = element.get(0)
    if element.selectedIndex > -1 then element.options[element.selectedIndex].value else null

  isValueInDropDown: (element, value) ->
    if element instanceof jQuery
      element = element.get(0)
    for option in element.options
      if option.value == value
        return true
    return false

  moveToPending: ->
    @clearEventFilters()
    @updateStatus('PENDING')
    @updateTaxYearOptions()

  moveToSubmitted: ->
    @clearEventFilters()
    @updateStatus('SUBMITTED')
    @updateTaxYearOptions()

  export: ->
    @exportTaxWeek()

  exportTaxWeek: ->
    ServerProxy.sendRequest("/office/check_if_pay_weeks_okay_to_export", {tax_week_id: @getCurrentTaxWeekId(), status: @statusDropdown.val()}, Actor(
      requestSuccess: (data) =>
        $.fileDownload("/office/export_pay_week",
          httpMethod: 'POST',
          data: {tax_week_id: @getCurrentTaxWeekId(), status: @statusDropdown.val()},
          failCallback: ->
            alert("Sorry, a server error occurred and the file could not be downloaded. Please report this to the application developers."))
      requestError: (data) =>
        NotificationPopup.requestError(data)))

  savePayWeekChanges: (changes, source) =>
    @saveChanges(changes, source, @payrollGrid, @payrollColumnIndex, @payroll_columns, @payrollAutosaving, '/office/update_pay_weeks')

  saveTimesheetChanges: (changes, source) =>
    @saveChanges(changes, source,  @timesheetGrid, @timesheetColumnIndex, @timesheet_columns, @timesheetAutosaving, '/office/update_timesheet_entries')

  saveChanges: (changes, source, grid, columnIndex, columns, autoSaving, route) =>
    ##### Rows with validation fire two change events, one with the data before validation, and one with the data after.
    ##### So we ignore the first event if this column has validation
    if source != 'loadData'
      if changes
        data = {}
        data['data']={}
        for change in changes
          #change: [row, col, oldVal, newVal]
          row = change[0]
          col = change[1]
          val = change[3]
          if val?
            id = grid.handsontable('getInstance').getDataAtCell(row, columnIndex['id'])
            data['data'][id] = {}
            data['data'][id][columns[col].name]=val
        unless data.empty?
          autoSaving = true
          data['autocalc'] = true
          data['tax_week_id'] = @getCurrentTaxWeekId()
          ServerProxy.saveChanges(route, data, Actor(
            requestSuccess: =>
              @redraw()), @db)

  updateStatus: (status) =>
    pwData = @payrollGrid.handsontable('getInstance').getSourceData()
    data = {}
    if(pwData.length > 0)
      data['data']={}
      for row in pwData
        id = row[@payrollColumnIndex['id']]
        data['data'][id] = {}
        data['data'][id]['status'] = status #override current status with desired status
    unless data.empty?
      @payrollAutosaving = true
      ServerProxy.saveChanges("/office/update_pay_weeks/", data, null, @db)

  isEditableField: (field) ->
    (field.hidden == undefined || field.hidden == false) && (field.props.readOnly == undefined || field.props.readOnly == false)

  taxWeekDataPresent: =>
    if @payrollGrid.handsontable('getInstance').getSourceData().length > 0 then true else false

  viewEmployeeDetailUpdates: =>
    popup=window.open("/office/payroll_detail_changes?tax_week_id=#{@getCurrentTaxWeekId()}")
    if typeof(popup) == 'undefined'
      alert("You must unblock popups in order to see the weekly changes report")
    else
      popup.focus()

  getActiveDaysForEvent: (event_id) ->
    activeDays = []
    dayOfTheWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
    if event_id && event_id != ""
      event = @db.findId('events', parseInt(event_id))
      for date in @getDates(event.date_start, event.date_end)
        activeDays[@payrollColumnIndex[dayOfTheWeek[date.getDay(date)]]] = true
      activeDays
    else
      for day in dayOfTheWeek
        activeDays[@payrollColumnIndex[day]] = true
      activeDays

  Date.prototype.addDays = (days) ->
    dat = new Date(this.valueOf())
    dat.setDate(dat.getDate() + days)
    dat

  #Given an event, get the dates, in the current tax week, that this event covers.
  getDates: (startDate, stopDate) ->
    tax_week = @db.findId('tax_weeks', @getCurrentTaxWeekId())
    dateArray = []
    currentDate = max(startDate, tax_week.date_start)
    while currentDate <= min(stopDate, tax_week.date_end)
      dateArray.push(new Date(currentDate))
      currentDate = currentDate.addDays(1)
    dateArray

  getCurrentTaxWeekId: ->
    parseInt(@taxWeekDropdown.val())

  getCurrentEventId: ->
    event_id_string = @eventDropdown.val()
    if event_id_string? and event_id_string != ''
      parseInt(event_id_string)
    else
      undefined

  toggleSubview: ->
    if @shownSubview == 'timesheet'
      @viewport.find('.timesheet-view-only').hide()
      @viewport.find('.payroll-view-only').show()
      @reportDropdown.val('')
      @shownSubview = 'payroll'
    else
      @viewport.find('.payroll-view-only').hide()
      @viewport.find('.timesheet-view-only').show()
      @shownSubview = 'timesheet'
    @showHideStatusDependentElements()
    @showHideEditingElements()
    @redraw()

class PayrollReportDownloader
  constructor: (@payrollView, @db, @filterBar) ->

  records: (reportName) ->
    if @payrollView.shownSubview == 'timesheet'
      @db.queryAll('timesheet_entries', @filterBar.selectedFilters(), timesheetEntrySort)
    else
      @db.queryAll('pay_weeks', @filterBar.selectedFilters(), payweekSort)

  okForDownload: (reportName) ->
    records = @records(reportName)
    if records.length > 1000
      alert("Sorry, you can't generate a report for more than 1000 records at once. (Right now, " + records.length + " are selected.)")
      false
    else if records.length == 0
      alert("No records are selected for inclusion in the report.")
      false
    else
      true

  download: (reportName, format, dialog) ->
    if @okForDownload(reportName)
      downloadIt = =>
        records = @records(reportName)
        ids = records.map((r) -> r.id)
        $.fileDownload('/office/download_report', {
          httpMethod: 'POST',
          data: {format: format, ids: ids.join(','), report: reportName},
          successCallback: ->
            dialog.modal('hide')
          failCallback: ->
            alert("Sorry, a server error occurred and the report could not be downloaded.")
            dialog.modal('hide')
        })
      downloadIt()

window.PayrollView = PayrollView
