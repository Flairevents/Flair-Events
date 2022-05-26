class InvoicesView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Invoices'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)

    invoiceColumns = [
      {id: 'client_name',       name: 'Client'},
      {id: 'event_name',        name: 'Event', changes_with: ['status', 'event_name']},
      {id: 'event_dates',       name: 'Event Dates'}
      {id: 'status',            name: 'Status'},
      {id: 'booking_invoicing_notes', name: 'Booking Invoicing Notes'},
      {id: 'tax_week',          name: 'Tax Week'},
    ]

    invoiceFormBuilder = (invoice) =>
      [
        invoice.client_name,
        (if invoice.status == 'EMAILED' then "<span class='hilite event-name'>#{invoice.event_name}</span>" else "<span class='event-name'>#{invoice.event_name}</span>"),
        invoice.event_dates
        buildSelect(name: '[invoices]['+invoice.id+'][status]', options: [['New','NEW'],['Emailed','EMAILED'],['Sage','SAGE']], selected: invoice.status, class: "status-dropdown"),
        "<input type='text' size='50' name='[invoices][" + invoice.id + "][booking_invoicing_notes]' value='" + (invoice.booking_invoicing_notes).replace("'", "\\'") + "'/>",
        invoice.tax_week
      ]

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'invoices', invoiceColumns, invoiceFormBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_invoices', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      select: (data) => @select(data)
      deselect: =>  @commandBar.disableCommands('edit', 'delete')
      activate: (data) => @activate(data)
      page: => @page()))

    autosize(@viewport.find('.record-edit textarea'))
    autosize(@viewport.find('.record-new textarea'))
    fillInEditForm = ($form, record) =>
      @fillInClientsDropdown($form, record)
      @fillInEventsDropdown($form, record)
      @fillInTaxWeeksDropdown($form, record)
      event_client = @db.findId('event_clients', record.event_client_id)
      event = @db.findId('events', event_client.event_id)
      officer = @db.findId('officers', event.office_manager_id)
      client = @db.findId('clients', event_client.client_id)
      booking = @db.findId('bookings', event_client.booking_id)
      fillInput($form.node('invoice[status]'), record.status)
      fillDateInput($($form.node('invoice[date_emailed]')), record.date_emailed)
      fillInput($form.node('invoice[who]'), record.who)
      $form.find('#invoice_booking_invoicing_notes').text(booking && booking.invoicing || '')
      $form.find('#invoice_office_manager').text(if officer then prospectName(officer) else '')
      $form.find('#invoice_client_rates').text(booking && booking.rates || '')
      $form.find('#invoice_client_notes').text(client.invoice_notes || '')

    fillInNewForm = ($form, record) =>
      @fillInClientsDropdown($form, record)
      @fillInEventsDropdown($form, record)
      @fillInTaxWeeksDropdown($form, record)
      fillInput($form.node('invoice[status]'), 'NEW')
      fillInput($form.node('invoice[date_emailed]'), '')
      fillInput($form.node('invoice[who]'), '')
      $form.find('#invoice_booking_invoicing_notes').text('')
      $form.find('#invoice_office_manager').text('')
      $form.find('#invoice_client_rates').text('')
      $form.find('#invoice_client_notes').text('')

    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    @newForm  = new RecordEditForm(@viewport.find('.record-new'), @, fillInNewForm)
    @newForm  = new SlidingForm(@newForm)

    @reportDownloader = new ReportDownloader(@table)
    @reportDialog = new ReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new ReportMenu(@viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    @viewport.find('.refresh-data').click(=>
      @db.refreshData())

    @viewport.on('keydown', (e) =>
      switch e.which
        when 33 # page up
          @table.prevPage()
          false
        when 34 # page down
          @table.nextPage()
          false
    )

    $(@node('client_id')).on('change', @clientChangeHandler)
    $(@node('event_id' )).on('change', @eventChangeHandler)
    @viewport.find('.filter-bar #tax_year_id').change => @fillInTaxWeekFilterDropdown()

    @db.onUpdate('tax_years', => @fillInTaxYearFilterDropdown())
    @db.onUpdate('tax_weeks', (updateType) =>
      @fillInTaxWeekFilterDropdown()
      ##### The following is only called on the initial load (sets default tax week)
      if updateType == 'load'
        last_week = new Date
        last_week.setDate(last_week.getDate()-7)
        last_week.setHours(0,0,0,0)
        last_tax_week = @db.queryAll('tax_weeks', {includes_date: last_week})[0]
        @viewport.find('.filter-bar #tax_year_id').val(@db.findId('tax_years', last_tax_week.tax_year_id).id).change()
        @viewport.find('.filter-bar #tax_week_id').val(last_tax_week.id).change()
    )
    @db.onUpdate('invoices', => @redraw())

  draw: ->
    @table.draw()
    @updateRowHandlers()

  page: ->
    @updateRowHandlers()

  fillInTaxYearFilterDropdown: ->
    $taxYearFilterDropdown = @viewport.find('#tax_year_id')
    val = $taxYearFilterDropdown.val()
    options = [['','']]
    for tax_year in @db.queryAll('tax_years')
      options.push([printTaxYear(tax_year), tax_year.id])
    options = options.sort (o1, o2) ->
      if o1[0] > o2[0] then 1 else if o1[0] < o2[0] then -1 else 0
    $taxYearFilterDropdown.html(buildOptions(options))
    $taxYearFilterDropdown.val(val) if val
    $taxYearFilterDropdown.change()

  fillInTaxWeekFilterDropdown: ->
    $taxYearFilterDropdown = @viewport.find('#tax_year_id')
    $taxWeekFilterDropdown = @viewport.find('#tax_week_id')
    val = $taxWeekFilterDropdown.val()
    options = [['','']]
    if $taxYearFilterDropdown.val() == ''
      $taxWeekFilterDropdown.empty()
    else
      tax_weeks = @db.queryAll('tax_weeks', {tax_year_id: parseInt($taxYearFilterDropdown.val())})
      tax_weeks = tax_weeks.sort (o1, o2) ->
        if o1.week > o2.week then 1 else if o1.week < o2.week then -1 else 0
      for tax_week in tax_weeks
        options.push([printTaxWeek(tax_week), tax_week.id])
      $taxWeekFilterDropdown.html(buildOptions(options))
      $taxWeekFilterDropdown.val(val) if val

  fillInClientsDropdown: ($parent, record) ->
    clients = @db.queryAll('clients', {active: 'true'}, 'name')
    options = [['','']]
    for client in clients
      has_active_events = false
      for event_client in @db.queryAll('event_clients', {client_id: client.id})
        events = @db.queryAll('events', {id: event_client.event_id, active: true})
        if events.length > 0
          has_active_events = true
      if has_active_events
        options.push([client.name, client.id])
    $client_dropdown = $($parent.node('client_id'))
    $client_dropdown.html(buildOptions(options))
    $client_dropdown.val(@db.findId('event_clients', record.event_client_id).client_id) if record && record.event_client_id
    $client_dropdown.change()

  clientChangeHandler: (e) =>
    if $parent = @getForm()
      @fillInEventsDropdown($parent, null)

  fillInEventsDropdown: ($parent, record) ->
    client_id = $parent.node('client_id').value
    $event_dropdown = $($parent.node('event_id'))
    $event_dropdown.empty()
    if client_id && client_id != ''
      event_clients = @db.queryAll('event_clients', {client_id: parseInt(client_id)}, 'name')
      options = []
      for event_client in event_clients
        event = @db.findId('events', event_client.event_id)
        options.push([event.name, event.id]) if event.status == 'OPEN' || event.status == 'HAPPENING' || event.status == 'FINISHED'
      # If event for existing invoice is not in the list (ie. such as when the event is finished or closed), then add
      # it to the list
      if record && record.event_client_id
        event = @db.findId('events', @db.findId('event_clients', record.event_client_id).event_id)
        event_ids = (option[1] for option in options when option[1] == event.id)
        if event_ids.length == 0
          option = new Option(event.name, event.id)
          options.push([event.name, event.id])
      options = options.sort (o1, o2) ->
        if o1[0] > o2[0] then 1 else if o1[0] < o2[0] then -1 else 0
      $event_dropdown.html(buildOptions(options))
      $event_dropdown.val(event.id) if record && record.event_client_id
      $event_dropdown.change()

  eventChangeHandler: (e) =>
    if $parent = @getForm()
      @fillInTaxWeeksDropdown($parent, null)

  fillInTaxWeeksDropdown: ($parent, record) ->
    event_id = $parent.node('event_id').value
    $tax_week_dropdown = $($parent.node('invoice[tax_week_id]'))
    $tax_week_dropdown.empty()
    if event_id && event_id != ''
      event = @db.findId('events', event_id)
      options = []
      for tax_year in @db.queryAll('tax_years', {overlaps_dates: [event.date_start, event.date_end]})
        for tax_week in @db.queryAll('tax_weeks', {overlaps_dates: [event.date_start, event.date_end], tax_year_id: tax_year.id})
          options.push([printTaxYearAndWeek(tax_year, tax_week), tax_week.id])
      $tax_week_dropdown.html(buildOptions(options))
      $tax_week_dropdown.val(record.tax_week_id) if record && record.tax_week_id
      $tax_week_dropdown.change()

  getForm: () ->
    if @newForm.in()
      @viewport.find('.record-new')
    else if @editForm.in()
      @viewport.find('.record-edit')
    else
      null

  updateRowHandlers: ->
    rebind(@viewport.find('.status-dropdown'), 'change', @saveCurrentRow)

  saveCurrentRow: =>
    @table.saveCurrentRow()

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#applicants-details"]').tab('show')
      @newForm.newRecord())

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editForm.editRecord(record))

  clearFilters: ->
    @filterBar.clearFilters()
    @viewport.find('#tax_week_id').empty()
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @draw()

  select: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=> @editForm.editRecord(data.record))

  activate: (data) ->
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing())
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editForm.editRecord(data.record))
    else
      @editForm.editRecord(data.record)

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
      else if @newForm.in()
        @newForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
    else if @newForm.in()
      @newForm.stopEditing()

  postSlideIn: ->
    if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))
    else if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))

  saveAll: ->
    @tryToSave(=> @refreshForm())

  deleteRecord: ->
    if record = @table.selectedRecord()
      ServerProxy.sendRequest('/office/delete_invoice/'+record.id, {}, ErrorOnlyPopup, @db)

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  refreshForm: () ->
    if @editForm.in()
      @editForm.refreshForm(@db, 'invoices')

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_invoice/', @db, actor, 'invoices')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_invoice', @db, actor, 'invoices')
    else
      callback()

  numRows: (numRows) =>
    if @table.pageSize #This won't be defined if you're not a manager
      @table.pageSize(numRows)
      @table.draw()

  dirty: ->
    @commandBar.enableCommand('revert')
  clean: ->
    @commandBar.disableCommand('revert')

  rowSelected: (data) ->
    if data.index?
      @table.selectRow(data.index)
    else
      @table.selectRecord(data.record)

    @commandBar.enableCommands('edit', 'delete')

window.InvoicesView = InvoicesView
