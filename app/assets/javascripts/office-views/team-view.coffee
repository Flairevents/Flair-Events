class TeamView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Team'

    prospectColumns = [
      {name: "<input type='checkbox' id='team_bulk_select' class='never-dirty'></input>", sortable: false},
      {id:"name",                 name:"Name"},
      {id: 'skills',              name:"Skills & Interests"},
      {id:"city",                 name:"City"}
      {id:"prospect_character",   name:"Size"},
      {id:"last_login",           name:"Active"},
      {id:"no_show_contracts",    name:"NS"},
      {id:"cancelled_eighteen_hrs_contracts",       name:"CX-18"},
      {name:"App"},
      {id: 'team_notes',          name: 'Team Notes'},
      {id:"date_start",           name:"Start Date", type:"date"},
      {id:"gender",               name:"Gender"},
      {id:"age",                  name:"Age", type:"number"},
      {id:"region_id",            name:"Region"},
      {id:"status",               name:"Status"}
    ]
    now = new Date
    lastSixthStart = new Date 1900+now.getYear(), now.getMonth()-6, 1
    lastMonthEnd = new Date 1900+now.getYear(), now.getMonth(), 0
    getDates = (startDate, stopDate) ->
      dateArray = []
      currentDate = moment(startDate)
      stopDate = moment(stopDate)
      while currentDate <= stopDate
        dateArray.push moment(currentDate).format('YYYY-MM-DD')
        currentDate = moment(currentDate).add(1, 'days')
      dateArray

    prospectFormBuilder = (prospect) =>
      gigRequests = @db.queryAll('gig_requests', {prospect_id: prospect.id} )
      prospect_ids = []
      filteredGigRequests = gigRequests.filter ((gr) => moment(gr.created_at).format('YYYY-MM-DD') in getDates(lastSixthStart, lastMonthEnd))
      prospect_ids = (gr.prospect_id for gr in filteredGigRequests)
      isActive = moment(prospect.last_login).format('YYYY-MM-DD') in getDates(lastSixthStart, lastMonthEnd) && prospect.id in prospect_ids
      avg_rating = prospect.avg_rating
      if avg_rating == null
        avg_rating = 0

      flag = prospect.flag_photo
      if flag == null then flag = ""

      @prospectColumnName = "<b class='team-view-name-size'>" + escapeHTML(prospectName(prospect)) + "</b>"
      if prospect.age? && prospect.age < 18
        @prospectColumnName = "<span class='red-text team-view-name-size'><b>" + escapeHTML(prospectName(prospect)) + "</b></span>"
      ["<input type='checkbox' class='select_checkbox_team never-dirty' index='#{prospect.id}' #{(if window.isSelected('team', prospect.id) then 'checked=\'checked\'' else '')}</input>",
       "<div class='team-size-name-column-width'><img src='/prospect_photo/#{prospect.id}?force_refresh=#{Math.random()}' class='team_photo'>" + @prospectColumnName + " <br> <small style='float: left;'>R: " + escapeHTML(avg_rating) + "</small>" + " <small style='float: left; margin-left: 10px;'> #E:" + escapeHTML(prospect.n_gigs) + "</small>  " + flag + " </div>",
       prospect.skills,
       prospect.city,
       prospect.prospect_character,
       if isActive then 'Yes' else 'No',
       if prospect.no_show_contracts != null && prospect.no_show_contracts > 0 then prospect.no_show_contracts else "",
       if prospect.cancelled_eighteen_hrs_contracts != null && prospect.cancelled_eighteen_hrs_contracts > 0 then prospect.cancelled_eighteen_hrs_contracts else "",
       "",
       [buildTextInput({name: "[prospects][" + prospect.id + "][team_notes]", value: prospect.team_notes}),
         ($td) =>
           $td.find('input').attr('title', prospect.team_notes).tooltip('fixTitle') if prospect.team_notes && prospect.team_notes.length > 35
       ],
       printDate(prospect.date_start),
       prospect.gender,
       prospect.age,
       if prospect.region_id then window.Regions[prospect.region_id] else '',
       prospect.status
      ]

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'prospects', prospectColumns, prospectFormBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_prospects', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      select: (data) => @select(data)
      deselect: => @commandBar.disableCommands('edit', 'ids', 'assign')
      activate: (data) => @activate(data)
      clean: => @clean()
      dirty: => @dirty()
      page: => @page()),
      { saveOnChange: true })

    @table.sortOnColumn('name', true)
    @table.setFilters(@filterBar.selectedFilters())

    @map = new MapView(@viewport.find('.map-view'), @)
    @map = new QueryMap(@map, @db, 'prospects')
    @map.setFilters(@filterBar.selectedFilters())

    @shownSubview = 'table'

    autosize(@viewport.find('.record-edit textarea'))
    autosize(@viewport.find('.record-new textarea'))
    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, @fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    @newForm  = new RecordEditForm(@viewport.find('.record-new'), @, @fillInNewForm)
    @newForm  = new SlidingForm(@newForm)

    $(@newForm.node('prospect[id_type]')).change(->
      if $(this).val() == 'Work/Residency Visa'
        $('.record-new .non-eu-only').show()
        $('.record-new .share-code').show()
        $('.record-new .non-share-code').hide()
        $('.record-new .eu-only').hide()
      else if $(this).val() == 'Pass Visa'
        $('.record-new .non-eu-only').show()
        $('.record-new .share-code').hide()
        $('.record-new .non-share-code').show()
        $('.record-new .eu-only').hide()
      else
        $('.record-new .non-eu-only').hide()
        $('.record-new .share-code').hide()
        $('.record-new .non-share-code').show()
        $('.record-new .eu-only').show())
    $(@editForm.node('prospect[id_type]')).change(->
      if $(this).val() == 'Work/Residency Visa'
        $('.record-edit .non-eu-only').show()
        $('.record-edit .share-code').show()
        $('.record-edit .non-share-code').hide()
        $('.record-edit .eu-only').hide()
      else if $(this).val() == 'Pass Visa'
        $('.record-edit .non-eu-only').show()
        $('.record-edit .share-code').hide()
        $('.record-edit .non-share-code').show()
        $('.record-edit .eu-only').hide()
      else
        $('.record-edit .non-eu-only').hide()
        $('.record-edit .share-code').hide()
        $('.record-edit .non-share-code').show()
        $('.record-edit .eu-only').show())

    @viewport.find(".prospect_reject_photo").click(=> @rejectPhoto())

    @bulk_select = $('#team_bulk_select')
    @bulk_select.bind('click', @teamBulkSelectClickHandler)
    @bulk_select.bind('change', @teamBulkSelectChangeHandler)

    @previousStatus = ''
    @addStatusCallback()
    @addSendMarketingEmailCallback()

    @eventsList = @setupEventList('#prospect-events')
    @futureEventsList = @setupFutureEventList('#prospect-future-events')
    @requestList = @setupRequestList('#prospect-requests')
    @actionList = @setupActionList('#prospect-action-takens')

    @scannedIdDialog = @viewport.find('.scanned-id-dialog')
    @scannedIdDialog.modal({show: false})
    @scannedIdDialog.find('.approve-id-btn').click(=> @approveIds())
    @scannedIdDialog.find('.reject-id-btn').click(=> @rejectIds())

    @scannedDBSDialog = @viewport.find('.scanned-dbs-dialog')
    @scannedDBSDialog.modal({show: false})

    @scannedBarLicenseDialog = @viewport.find('.scanned-bar-license-dialog')
    @scannedBarLicenseDialog.modal({show: false})

    @assignEventsDialog = @viewport.find('.multi-assigner')
    @assignEventsDialog.modal({show: false})
    @assigner = new MultiAssigner(@assignEventsDialog.find('.modal-body'), @)

    @bulkSMSDialog = @viewport.find('.bulk-sms-dialog')

    @reportDownloader = new ReportDownloader(@table)
    @reportDialog = new ReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new ReportMenu(@viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    @regionDropdown = @viewport.find('.filter-bar select[name="region_name"]')
    @regionDropdown.on('change', (e) =>
      if @regionDropdown.val() != ''
        regionID = window.db.queryAll('regions', {name: @regionDropdown.val()})[0].id
        @buildCityDropdown(regionID)
      else
        @buildCityDropdown(''))

    @gigDropdown = @viewport.find('.filter-bar select[name="gig"]')
    @noGigDropdown = @viewport.find('.filter-bar select[name="no_gig"]')
    @buildEventDropdown(@gigDropdown)
    @buildEventDropdown(@noGigDropdown)
    @gigDropdown.on('change', (e) =>
      @noGigDropdown.val('').change() if @noGigDropdown.val() != '' && @gigDropdown.val() != ''
      @updateDistanceDropdown(@gigDropdown))
    @noGigDropdown.on('change', (e) =>
      @gigDropdown.val('').change() if @gigDropdown.val() != '' && @noGigDropdown.val() != ''
      @updateDistanceDropdown(@noGigDropdown))

    @viewport.find('.autozoom').change(=>
      @map.setAutozoom(@viewport.find('.autozoom').is(':checked')))

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

    @viewport.find('.record-new .photo-area').hide()

    @db.onUpdate('text_blocks', =>
      @rebuildEmailTemplateDropdown())
    @rebuildEmailTemplateDropdown()

    @viewport.find('.command-view-id').click(=> @showScannedIds())
    @viewport.find('.command-upload-id').click(=> @uploadScannedIds())
    @viewport.find('.command-upload-photo').click(=> @uploadProspectPhoto())
    @viewport.find('.command-view-bar-license').click(=> @showScannedBarLicense())
    @viewport.find('.command-upload-bar-license').click(=> @uploadScannedBarLicense())
    @viewport.find('.command-view-dbs').click(=> @showScannedDBS())
    @viewport.find('.command-upload-dbs').click(=> @uploadScannedDBS())
    @viewport.find('.command-password-reset-link').click(=> @passwordResetLink())
    @viewport.find('.command-unlock-account').click(=> @unlockAccount())

    @db.onUpdate('gigs', =>
      if @editForm.in()
        @eventsList.draw()
        @futureEventsList.draw()
        @viewport.find('.prospect-events-tab').text('Events (' + @eventsList.totalRecords() + ')')
        @viewport.find('.prospect-future-events-tab').text('Future Events (' + @futureEventsList.totalRecords() + ')'))
    @db.onUpdate('gig_requests', =>
      if @editForm.in()
        @requestList.draw()
        @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')'))
    @db.onUpdate('action_takens', =>
      if @editForm.in()
        @actionList.draw()
        @viewport.find('.prospect-action-taken-tab').text('Action Logs (' + @actionList.totalRecords() + ')'))
    @db.onUpdate('events', =>
      @buildEventDropdown(@gigDropdown)
      @buildEventDropdown(@noGigDropdown))
    @db.onUpdate('prospects', =>
      EventsView::updateStatistics()
      @redraw())

  draw: ->
    if @shownSubview == 'table'
      @table.draw()
      @updateRowHandlers()
    else
      @map.draw()

  page: ->
    @updateRowHandlers()

  updateRowHandlers: ->
    rebind(@viewport.find('.select_checkbox_team'), 'change', @selectTeamCheckboxHandler)

  selectTeamCheckboxHandler: (event) =>
    $checkbox = $(event.target)
    id = $checkbox.attr('index')
    if $checkbox.prop('checked') then selectRecord('team', id) else deselectRecord('team', id)
    n_total_teams = @getFilteredTeams().length
    n_selected = nSelected('team')

    if n_selected == 0
      @bulk_select.prop('indeterminate', false)
      @bulk_select.prop('checked', false)
    else if n_selected == n_total_teams
      @bulk_select.prop('indeterminate', false)
      @bulk_select.prop('checked', true)
    else
      @bulk_select.prop('indeterminate', true)
    event.stopPropagation()

  teamBulkSelectClickHandler: (event) =>
    event.stopPropagation()

  teamBulkSelectChangeHandler: (event) =>
    @bulk_select.prop('indeterminate', false)
    if @bulk_select.prop('checked')
      @viewport.find('.record-list-team').find('.select_checkbox_team').prop('checked', true)
      selectRecord('team', team.id) for team in @getFilteredTeams()
    else
      @viewport.find('.record-list-team').find('.select_checkbox_team').prop('checked', false)
      clearAllSelected('team')

  getFilteredTeams: () =>
    console.log("filter method")
    filters = {}
    filters['status'] = 'EMPLOYEE'
    @db.queryAll('prospects', filters)

  saveCurrentRow: =>
    @table.saveCurrentRow()

  toggleSubview: ->
    if @shownSubview == 'table'
      @viewport.find('.list-view, .list-view-only').hide()
      @map.draw()
      @viewport.find('.map-view, .map-view-only').show()
      if mapWidget = @map.googleMap()
        gmapevt.trigger(mapWidget, 'resize')
      @shownSubview = 'map'
    else
      @viewport.find('.map-view, .map-view-only').hide()
      @table.draw()
      @viewport.find('.list-view, .list-view-only').show()
      @shownSubview = 'table'

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#prospect-details"]').tab('show')
      @newForm.newRecord()
      @newForm.node('prospect[status]').value = 'EMPLOYEE')

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editForm.editRecord(record))

  setupFutureEventList: (containerSelector) ->
    eventColumns = [
      {name: 'Event Name',   id: 'event_name'},
      {name: 'Date',   id: 'date_start', type: 'date'},
      {name: 'Main Job',    id: 'job_name'},
      {name: 'Distance'}
      {name: 'Notes',  id: 'notes'}]

    dates = []
    prsId = 0
    requestRowBuilder = (gig) ->
      if prsId != gig.prospect_id
        dates = []
        prsId = gig.prospect_id
        allRequest = window.db.queryAll('gigs', {prospect_id: gig.prospect_id, future_only: true}, 'date_start')
        dates = (printDate(x.date_start) for x in allRequest)

      event = window.db.findId('events', gig.event_id)
      prospect = window.db.findId('prospects', gig.prospect_id)
      dist = 0
      if (coord1 = coordinatesForRecord(prospect)) && (coord2 = coordinatesForRecord(event))
        dist = distanceBetweenPointsInMiles(coord1, coord2)

      eventNotes = ''
      if gig.notes != null
        eventNotes = gig.notes
      event_task = window.db.findId('events', gig.event_id)

      color = ''
      count = (dates.filter (val) => val == printDate(gig.date_start)).length
      if count > 1
        color = 'yellow'

      ["<div style='background-color: " + color + ";'> " + escapeHTML(gig.event_name)+ " </div>",
        printDate(gig.date_start) ,
        escapeHTML(gig.job_name),
        dist,
        "<input type='text' name='gigs[#{gig.id}][notes]' class='form-control' value='"+eventNotes+"' style='width: 100%;'>"]

    eventsList = new ListView(@db, @viewport.find(containerSelector), 'gigs', eventColumns)
    eventsList.rowBuilder(requestRowBuilder)
    eventsList.sortOnColumn('date_start', false)
    return eventsList

  setupEventList: (containerSelector) ->
    eventColumns = [
      {name: 'Event Name',   id: 'event_name'},
      {name: 'Date',   id: 'date_start', type: 'date'},
      {name: 'Main Job',    id: 'job_name'},
      {name: 'Full'},
      {name: 'Rating', id: 'rating', type: 'number'},
      {name: 'Client Notes'}
      {name: 'HQ Notes',  id: 'notes'}]

    requestRowBuilder = (gig) ->
      eventNotes = ''
      if gig.notes != null
        eventNotes = gig.notes
      event_task = window.db.findId('events', gig.event_id)
      [escapeHTML(gig.event_name),
      printDate(gig.date_start),
      escapeHTML(gig.job_name),
      'YES',
      if gig.rating != null then escapeHTML(gig.rating),
      "<input type='text' class='form-control' style='min-width: 100%;'>",
      "<input type='text' name='gigs[#{gig.id}][notes]' class='form-control' value='"+eventNotes+"' style='min-width: 100%;'>"]

    eventsList = new ListView(@db, @viewport.find(containerSelector), 'gigs', eventColumns)
    eventsList.rowBuilder(requestRowBuilder)
    eventsList.sortOnColumn('date_start', false)
    return eventsList

  setupRequestList: (containerSelector) ->
    requestColumns = [
      {name: 'Event Name',    id: 'event_name'},
      {name: 'Date',    id: 'date_start', type: 'date'},
      {name: 'Applied Job'},
      {name: 'Linked Skills',       id: 'skills'},
      {name: 'Best'},
      {name: 'Distance'},
      {name: 'Notes', id: 'notes'},
      {name: 'Hire?',   sortable: false},
      {name: 'Spare', id: 'spare'}
      {name: 'Reject?', sortable: false},
    ]
    dates = []
    prsId = 0
    requestRowBuilder = (gig_request) ->
      console.log(gig_request)
      if prsId != gig_request.prospect_id
        dates = []
        prsId = gig_request.prospect_id
        allRequest = window.db.queryAll('gig_requests', {prospect_id: gig_request.prospect_id, future_only: true, gig_id: null}, 'date_start')
        dates = (printDate(x.date_start) for x in allRequest)
        console.log(allRequest)

      event = window.db.findId('events', gig_request.event_id)
      prospect = window.db.findId('prospects', gig_request.prospect_id)
      eventNote = escapeHTML(event.notes)
      dist = 0
      if (coord1 = coordinatesForRecord(prospect)) && (coord2 = coordinatesForRecord(event))
        dist = distanceBetweenPointsInMiles(coord1, coord2)

      color = ''
      count = (dates.filter (val) => val == printDate(gig_request.date_start)).length
      if count > 1
        color = 'yellow'

      [ "<div style='background-color: " + color + ";'> " + escapeHTML(gig_request.event_name) + " </div>",
        printDate(gig_request.date_start),
       "<div style='min-width: 100px'>#{window.db.findId('jobs', gig_request.job_id).name}</div>",
        gig_request.skills,
        "<input type='checkbox' >" ,
        dist,
        [buildTextInput({name: "[gig_requests][" + gig_request.id + "][notes]", value: gig_request.notes, style: 'width: 100%;'}),
          ($td) =>
            $td.find('input').attr('title', gig_request.notes).tooltip('fixTitle') if gig_request.notes && gig_request.notes.length > 35
        ]
        "<input type='checkbox' class='hire-checkbox big-box' value='" + gig_request.id + "'>",
        "<input type='checkbox' class='big-box' onclick='ServerProxy.saveChanges(\"/office/set_spare/#{gig_request.id}\", {spare: $(this).is(\":checked\")}, null, window.db)' #{if gig_request.spare then 'checked' else ''}>",
        "<input type='checkbox' class='reject-checkbox big-box' value='" + gig_request.id + "'>"]
    requestList = new EditableStaticListView(@db, @viewport.find(containerSelector), 'gig_requests', requestColumns, requestRowBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_gig_requests', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      clean: => @clean()
      dirty: => @dirty()))
    requestList.sortOnColumn('date_start', true)
    requestList.setFilters({gig_id: null})
    @viewport.find('.hire-btn').click(=>
      requestList.saveCurrentRow()
      requestIds = $.makeArray(@viewport.find(containerSelector + ' .hire-checkbox:checked')).map((check) -> $(check).attr('value'))
      message = warningForOtherManagers(requestIds)
      if message != ''
        myDb = @db
        bootbox.confirm({
          message: message,
          buttons: {
            confirm: {
              label: 'Hire Agreed',
            }
          },
          callback:(result) ->
            if result == true
              ServerProxy.sendRequest('/office/create_gigs', {gig_requests: requestIds}, Actor(
                requestSuccess: =>
                requestList.draw()), myDb)
        })
      else
        if requestIds.length > 0
          ServerProxy.saveChanges('/office/create_gigs', {gig_requests: requestIds}, Actor(
            requestSuccess: =>
              requestList.draw()), @db))
    @viewport.find('.reject-btn').click(=>
      requestIds = $.makeArray(@viewport.find(containerSelector + ' .reject-checkbox:checked')).map((check) -> $(check).attr('value'))
      if requestIds.length > 0
        fnRmv = (params) => ServerProxy.saveChanges('/office/delete_gig_requests', $.extend({gig_requests: requestIds}, params), Actor(
          requestSuccess: =>
            requestList.draw()
            prospectId = @viewport.find('.record-edit .prospect_id').html()
            @editForm.node('prospect[notes]').value = @db.findId('prospects', prospectId).notes), @db)
        showReasonDialog('Decline', fnRmv))
    return requestList

  setupActionList: (containerSelector) ->
    actionColumns = [
      {name: 'Event Name',    id: 'event_id'},
      {name: 'Action',         id: 'action'},
      {name: 'Reason',         id: 'reason'},
      {name: 'Date',          id: 'created_at', type: 'date'}]
    requestRowBuilder = (action_taken) ->
      event = window.db.findId('events', action_taken.event_id)
      [event.name,
       action_taken.action,
       action_taken.reason,
       moment(action_taken.created_at).format('YYYY-MM-DD')]

    actionList = new ListView(@db, @viewport.find(containerSelector), 'action_takens', actionColumns)
    actionList.rowBuilder(requestRowBuilder)
    actionList.sortOnColumn('created_at', false)
    return actionList

  showScannedBarLicense: ->
    if @scannedBarLicenseProspect = @table.selectedRecord()
      ServerProxy.sendRequest('/office/prospect_scanned_bar_licenses/'+@scannedBarLicenseProspect.id, {}, Actor(
        requestSuccess: (data) =>
          html = JST['office_views/_bar_license_approval'](data.result)
          @scannedBarLicenseDialog.find('.modal-body').html(html)
          @scannedBarLicenseDialog.modal('show')
          @scannedBarLicenseDialog.find('a.zoomimg').jqZoomIt()
        requestError: (data) =>
          NotificationPopup.requestError(data)), @db)

  showScannedDBS: ->
    if @scannedDBSProspect = @table.selectedRecord()
      ServerProxy.sendRequest('/office/prospect_scanned_dbses/'+@scannedDBSProspect.id, {}, Actor(
        requestSuccess: (data) =>
          html = JST['office_views/_dbs_approval'](data.result)
          @scannedDBSDialog.find('.modal-body').html(html)
          @scannedDBSDialog.modal('show')
          @scannedDBSDialog.find('a.zoomimg').jqZoomIt()
        requestError: (data) =>
          NotificationPopup.requestError(data)), @db)

  showScannedIds: ->
    if @scannedIdProspect = @table.selectedRecord()
      ServerProxy.sendRequest('/office/prospect_scanned_ids/'+@scannedIdProspect.id, {}, Actor(
        requestSuccess: (data) =>
          html = JST['office_views/_scanned_id'](data.result)
          @scannedIdDialog.find('.modal-body').html(html)
          if @scannedIdProspect.id_sighted?
            @scannedIdDialog.find('.approve-id-btn').hide()
          else
            @scannedIdDialog.find('.approve-id-btn').show()
          @scannedIdDialog.modal('show')
          @scannedIdDialog.find('a.zoomimg').jqZoomIt()
        requestError: (data) =>
          NotificationPopup.requestError(data)), @db)
  approveIds: ->
    numbers = @scannedIdDialog.find('input').serialize()
    ServerProxy.sendRequest('/office/approve_ids/'+@scannedIdProspect.id, numbers, Actor(
      requestSuccess: (data) =>
        @scannedIdDialog.modal('hide')
      requestError: (data) =>
        NotificationPopup.requestError(data)), @db)
  rejectIds: ->
    fnReject = (params) =>
      ServerProxy.sendRequest('/office/reject_ids/', $.extend({id: @scannedIdProspect.id}, params), Actor(
        requestSuccess: (data) =>
          if @editForm.in() && @editForm.editingId() == @scannedIdProspect.id
            @editForm.form.viewport.find('#id_number').val('')
            @editForm.form.viewport.find('#visa_number').val('')
            @editForm.form.viewport.find('#visa_expiry').val('')
          @scannedIdDialog.modal('hide')
        requestError: (data) =>
          NotificationPopup.requestError(data)), @db)
    showReasonDialog('Reject', fnReject, {id_messages: true, skip_log: true})

  uploadScannedIds: ->
    usi_window=window.open("/office/upload_scanned_ids/#{@table.selectedRecord().id}", '_blank')
    usi_window.onunload = =>
      @db.refreshData()

  uploadProspectPhoto: ->
    usi_window=window.open("/office/upload_prospect_photo/#{@table.selectedRecord().id}", '_blank')
    usi_window.onunload = =>
      @db.refreshData()

  uploadScannedBarLicense: ->
    usi_window=window.open("/office/upload_scanned_bar_license/#{@table.selectedRecord().id}", '_blank')
    usi_window.onunload = =>
      @db.refreshData()

  uploadScannedDBS: ->
    usi_window=window.open("/office/upload_scanned_dbses/#{@table.selectedRecord().id}", '_blank')
    usi_window.onunload = =>
      @db.refreshData()

  assignEvents: ->
    # fill in left and right lists in 'Assign Events' dialog before showing it
    @assignProspect = @table.selectedRecord()

    choices = []
    for evt in @db.queryAll('events', {active: true}, 'name')
      choices.push([evt.name, evt.id])

    selected = []
    for gig in @db.queryAll('gigs', {prospect_id: @assignProspect.id}, 'event_name')
      event = @db.findId('events', gig.event_id)
      if (event.status == 'OPEN' || event.status == 'HAPPENING' || event.status == 'FINISHED')
        selected.push([event.name, event.id])

    @assigner.choices(choices)
    @assigner.selected(selected)
    @assigner.draw()
    @assignEventsDialog.modal('show')

  saveAndCloseAssigner: ->
    data = @assigner.getChanges()
    if data.added.length > 0 || data.removed.length > 0
      callback = (result) =>
        if result
          ServerProxy.saveChanges('/office/add_remove_gigs', {
            prospect: @assignProspect.id,
            events_add: data.added,
            events_remove: data.removed},
            Tee(NotificationPopup,
              Actor(requestSuccess: =>
                @assignEventsDialog.modal('hide'))), @db)
      #If any events are locked, we prompt for confirmation before executing the callback
      checkForLockedEvents(data.added.concat(data.removed), callback)
    else
      @assignEventsDialog.modal('hide')

  showTeamForEvent: (data) ->
    @clearFilters()
    @filter({filters: @filterBar.selectedFilters()})


  clearFilters: ->
    @filterBar.clearFilters()
    @filterBar.viewport.node('status').value = 'EMPLOYEE'
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @map.setFilters(data.filters)
    @draw()
    if @shownSubview == 'table'
      @table.draw()
    else
      @map.draw()

  select: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=> @editForm.editRecord(data.record))
    if coord = coordinatesForRecord(data.record)
      @map.centerOnPoint(coord[0], coord[1])

  activate: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#prospect-details"]').tab('show'))
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editForm.editRecord(data.record))
    else
      @editForm.editRecord(data.record)

  postSlideIn: ->
    if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))
    else if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))

  saveAll: ->
    @tryToSave(-> null)

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#prospect-details"]').tab('show')
      else if @newForm.in()
        @newForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
      @viewport.find('.record-edit a[href="#prospect-details"]').tab('show')
    else if @newForm.in()
      @newForm.stopEditing()

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  showRequests: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="has_gig_requests"]').val('REQUESTS')
      @filter({filters: @filterBar.selectedFilters()}))

  showSpareRequests: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="has_gig_requests"]').val('SPARE')
      @filter({filters: @filterBar.selectedFilters()}))

  showPendingRequests: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="has_gig_requests"]').val('PENDING')
      @filter({filters: @filterBar.selectedFilters()}))
  showNoId: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="team_view_admin"]').val('id_false')
      @viewport.find('.filter-bar select[name="is_live"]').val('true')
      @filter({filters: @filterBar.selectedFilters()}))
  showNoTaxChoice: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="team_view_admin"]').val('tax_false')
      @viewport.find('.filter-bar select[name="is_live"]').val('true')
      @filter({filters: @filterBar.selectedFilters()}))
  showNoBankInfo: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="team_view_admin"]').val('bank_false')
      @viewport.find('.filter-bar select[name="is_live"]').val('true')
      @filter({filters: @filterBar.selectedFilters()}))
  showNoNINumber: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="team_view_admin"]').val('ni_false')
      @viewport.find('.filter-bar select[name="is_live"]').val('true')
      @filter({filters: @filterBar.selectedFilters()}))

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_prospect/', @db, actor, 'prospect')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_prospect', @db, actor, 'prospect')
    else
      callback()

  dirty: ->
    @commandBar.enableCommand('revert')
  clean: ->
    @commandBar.disableCommand('revert')

  bulkSMS: ->
    GigsView::bulkSMS.call(@, (@table.allRecords().filter (p) -> p.contact_via_text), 'Bulk Marketing SMS')

  bulkEmail: ->
    GigsView::bulkEmail.call(@, (@table.allRecords().filter (p) -> p.send_marketing_email), 'Bulk Marketing Email (All)')

  bulkEmailGrouped: ->
    GigsView::bulkEmail.call(@, (@table.allRecords().filter (p) -> p.send_marketing_email), 'Bulk Marketing Email (Groups of 400)', 400)

  rowSelected: (data) ->
    if data.index?
      @table.selectRow(data.index)
    else
      @table.selectRecord(data.record)

    record = @table.selectedRecord()
    @eventsList.setFilters({prospect_id: record.id, started_only: true})
    @futureEventsList.setFilters({prospect_id: record.id, future_only: true})
    @requestList.setFilters({prospect_id: record.id, future_only: true, gig_id: null})
    @actionList.setFilters({prospect_id: record.id})
    @actionList.draw()
    @eventsList.draw()
    @futureEventsList.draw()
    @requestList.draw()
    @viewport.find('.prospect-events-tab').text('Events (' + @eventsList.totalRecords() + ')')
    @viewport.find('.prospect-future-events-tab').text('Future Events (' + @futureEventsList.totalRecords() + ')')
    @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')')
    @viewport.find('.prospect-action-taken-tab').text('Action Logs (' + @actionList.totalRecords() + ')')
    @commandBar.enableCommands('edit', 'ids', 'assign')

  rebuildEmailTemplateDropdown: ->
    dropdown = @viewport.find('.email-dropdown')
    dropdown.empty()

    @db.queryAll('text_blocks', {type: 'email'}, 'key').forEach((block) =>
      option = $('<li><a href="#">' + escapeHTML(block.key) + '</a></li>')
      option.click(=>
        if @editForm.in()
          sendEmail(block, [@table.selectedRecord()])
        else
          sendEmail(block, @table.allRecords()))
      dropdown.append(option))

  passwordResetLink: ->
    if record = @table.selectedRecord()
      popup=window.open("/office/generate_forgot_password_text?id=#{record.id}")
      popup.focus()
    else
      alert("You must select a team member first")

  unlockAccount: ->
    if record = @table.selectedRecord()
      ServerProxy.sendRequest('/office/unlock_account', {id: record.id}, NotificationPopup, @db)
    else
      alert("You must select a team member first")

  populateCurrentClientChoices: (form, client_id) =>
    active_clients = @db.queryAll('clients', {active: 'true'})
    active_client_ids = (client.id for client in active_clients)
    options = []
    for client in active_clients
      options.push {text: client.name, id: client.id}
    if client_id? && client_id not in active_client_ids
      client = @db.findId('clients', client_id)
      options.push {text: client.name, id: client.id}
    options.sort (a, b) ->
      if a.text == b.text then 0 else if a.text < b.text then -1 else 1
    $client_id = form.node('prospect[client_id]')
    $client_id.innerHTML = '<option></option>'
    for option in options
      o = document.createElement('option')
      o.value = option.id
      o.innerHTML = option.text
      $client_id.appendChild(o)
    $($client_id).select2(placeholderoption: -> undefined) #placeholder: -> undefined shows a blank option
    if client_id?
      $($client_id).val(client_id).trigger('change')

  fillInNewForm: (form, record) =>
    @populateCurrentClientChoices(form, null)
    form.find('.error-message').hide()
    form.node('prospect[country]').value = 'england'
    $(form.node('prospect[status]')).change()

  formatDate = (date) ->
    if date == null
      return null

    timeStamp = [date.getDate(), (date.getMonth() + 1), date.getFullYear()].join("/")
    RE_findSingleDigits = /\b(\d)\b/g

    # Places a `0` in front of single digit numbers.
    timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )
    timeStamp.replace /\s/g, ""

  fillInEditForm: (form, record) =>
    @viewport.find('#prospect-profile').text('Loading...')
    $.ajax({url: '/office/fetch_profile/'+record.id, method: 'GET', dataType: 'html', cache: false})
      .done((html) => @viewport.find('#prospect-profile').html(html))

    @viewport.find('#prospect-changes').text('Loading...')
    $.ajax({url: '/office/fetch_change_request_log/'+record.id, method: 'GET', dataType: 'html', cache: false})
      .done((html) => @viewport.find('#prospect-changes').html(html))

    @viewport.find('#prospect-timesheet-notes').text('Loading...')
    $.ajax({url: '/office/fetch_timesheet_notes/'+record.id, method: 'GET', dataType: 'html', cache: false})
      .done((html) => @viewport.find('#prospect-timesheet-notes').html(html))

    form.find('select option:selected').removeAttr('selected')
    $errorMessage = form.find('.error-message')
    if record.status == "IGNORED"
      $errorMessage.text("Flagged Employee: Please See Notes").show()
    else
      $errorMessage.hide()

    form.find('.prospect_id').text(record.id)
    form.find('.prospect_registered').text(printDate(record.registered))
    if record.applicant_status == "UNCONFIRMED"
      form.find('.prospect_applicant_status').show()
    else
      form.find('.prospect_applicant_status').hide()

    $('.prospect_applicant_status').unbind('click')
    $('.prospect_applicant_status').bind 'click', ->
      alert = confirm("Verification email has been send to the user, click OK to proceed")
      if alert == true
        ServerProxy.saveChanges("/office/send_confirmation_email/"+record.id, {id: record.id}, Actor(
          requestSuccess: =>
            window.db.refreshData()
        ), window.db)

    form.find('.prospect_date_start').text(printDate(record.date_start))
    form.find('.prospect_date_end').text(printDate(record.date_end))

    fillInput(form.node('prospect[first_name]'), record.first_name)
    fillInput(form.node('prospect[last_name]'), record.last_name)
    fillInput(form.node('prospect[manager_level]'), record.manager_level)
    fillDateInput($(form.node('prospect[date_of_birth]')), record.date_of_birth)
    fillInput(form.node('prospect[gender]'), record.gender)
    fillInput(form.node('prospect[address]'), record.address)
    fillInput(form.node('prospect[address2]'), record.address2)
    fillInput(form.node('prospect[city]'), record.city)
    fillInput(form.node('prospect[post_code]'), record.post_code)
    fillInput(form.node('prospect[email]'), record.email)
    fillInput(form.node('prospect[city_of_study]'), record.city_of_study)
    form.node('prospect[send_marketing_email]').checked  = record.send_marketing_email
    form.node('prospect[send_marketing_email]').readOnly = !record.send_marketing_email
    fillInput(form.node('prospect[mobile_no]'), record.mobile_no)
    fillInput(form.node('prospect[home_no]'), record.home_no)
    fillInput(form.node('prospect[emergency_no]'), record.emergency_no)
    fillInput(form.node('prospect[emergency_name]'), record.emergency_name)
    fillInput(form.node('prospect[tax_choice]'), record.tax_choice)
    form.node('prospect[student_loan]').checked = record.student_loan
    fillInput(form.node('prospect[bank_account_name]'), record.bank_account_name)
    fillInput(form.node('prospect[bank_sort_code]'), record.bank_sort_code)
    fillInput(form.node('prospect[bar_license_type]'), record.bar_license_type)
    fillInput(form.node('prospect[bar_license_no]'), record.bar_license_no)
    totalNoOfContracts = window.db.queryAll('gigs', {prospect_id: record.id, started_only: true}).length
    fillInput(form.node('prospect[completed_contracts]'), totalNoOfContracts)
    fillInput(form.node('prospect[cancelled_contracts]'), if record.cancelled_contracts == null then 0 else record.cancelled_contracts)
    fillInput(form.node('prospect[cancelled_eighteen_hrs_contracts]'), if record.cancelled_eighteen_hrs_contracts == null then 0 else record.cancelled_eighteen_hrs_contracts)
    fillInput(form.node('prospect[no_show_contracts]'), if record.no_show_contracts == null then 0 else record.no_show_contracts)
    fillInput(form.node('prospect[non_confirmed_contracts]'), if record.non_confirmed_contracts == null then 0 else record.non_confirmed_contracts)
    fillInput(form.node('prospect[held_spare_contracts]'), if record.held_spare_contracts == null then 0 else record.held_spare_contracts)
    fillDateInput($(form.node('prospect[bar_license_expiry]')), record.bar_license_expiry)
    fillInput(form.node('prospect[bar_license_issued_by]'), record.bar_license_issued_by)
    fillInput(form.node('training_ethics'), record.training_ethics)
    fillInput(form.node('training_customer_service'), record.training_customer_service)
    fillInput(form.node('training_sports'), record.training_sports)
    fillInput(form.node('training_bar_hospitality'), record.training_bar_hospitality)
    fillInput(form.node('training_health_safety'), record.training_health_safety)
    fillInput(form.node('prospect[training_type]'), record.training_type)
    fillInput(form.node('prospect[dbs_qualification_type]'), record.dbs_qualification_type)
    form.node('prospect_agreed_terms').checked = record.agreed_terms
    fillInput(form.node('prospect[id_type]'), record.id_type)
    form.node('prospect[is_clean]').checked  = record.is_clean
    form.node('prospect[is_convicted]').checked  = record.is_convicted
    fillInput(form.node('prospect[test_site_code]'), record.test_site_code)
    fillInput(form.node('prospect[share_code]'), record.share_code)
    fillInput(form.node('prospect[condition]'), if record.condition == null then 'None' else record.condition)

    if record.id_type == 'Work/Residency Visa'
      form.find('.non-eu-only').show()
      form.find('.eu-only').hide()
      form.find('.share-code').show()
      form.find('.non-share-code').hide()
    else if record.id_type == 'Pass Visa'
      form.find('.non-eu-only').show()
      form.find('.eu-only').hide()
      form.find('.share-code').hide()
      form.find('.non-share-code').show()
    else
      form.find('.non-eu-only').hide()
      form.find('.eu-only').show()
      form.find('.share-code').hide()
      form.find('.non-share-code').show()
    fillInput(form.node('prospect[visa_number]'), record.visa_number)
    $visa_expiry = $(form.node('prospect[visa_expiry]'))
    fillDateInput($visa_expiry, record.visa_expiry)
    if record.visa_expiry? && record.visa_expiry < (new Date)
      $visa_expiry.addClass('visa_expired')
    else
      $visa_expiry.removeClass('visa_expired')
    form.node('prospect[visa_indefinite]').checked = record.visa_indefinite
    fillInput(form.node('prospect[id_sighted]'), printDate(record.id_sighted))
    fillInput(form.node('prospect[nationality_id]'), record.nationality_id)
    fillInput(form.node('prospect[country]'), record.country)
    fillInput(form.node('prospect[notes]'), record.notes)
    form.find('.prospect_photo').attr('src', '/prospect_photo/'+record.id+'?force_refresh='+Math.random())

    fillInput(form.node('prospect[bank_account_no]'), record.bank_account_no)
    fillInput(form.node('prospect[id_number]'), record.id_number)
    fillDateInput($(form.node('prospect[id_expiry]')), record.id_expiry)
    fillDateInput($(form.node('prospect[texted_date]')), record.texted_date)
    fillDateInput($(form.node('prospect[missed_interview_date]')), record.missed_interview_date)
    fillInput(form.node('prospect[headquarter]'), record.headquarter)
    fillInput(form.node('prospect[ni_number]'), record.ni_number)

    fillInput(form.node('prospect[dbs_certificate_number]'), record.dbs_certificate_number)
    fillDateInput($(form.node('prospect[dbs_issue_date]')), record.dbs_issue_date)
    
    if record.status == 'APPLICANT' then form.find('.only-applicants').show()

    questionnaires = window.db.queryAll('questionnaires', {prospect_id: record.id})

    if questionnaires.length > 0
      questionnaire = questionnaires[0]
      form.node('prospect[questionnaire[week_days_work]]').checked = questionnaire.week_days_work
      form.node('prospect[questionnaire[weekends_work]]').checked = questionnaire.weekends_work
      form.node('prospect[questionnaire[day_shifts_work]]').checked = questionnaire.day_shifts_work
      form.node('prospect[questionnaire[evening_shifts_work]]').checked = questionnaire.evening_shifts_work

      form.node('prospect[questionnaire[contact_via_text]]').checked = questionnaire.contact_via_text
      form.node('prospect[questionnaire[contact_via_whatsapp]]').checked = questionnaire.contact_via_whatsapp

      form.node('prospect[questionnaire[food_health_level_two_qualification]]').checked = questionnaire.food_health_level_two_qualification
      form.node('prospect[questionnaire[dbs_qualification]]').checked = questionnaire.dbs_qualification

      # Originally the checkbox was set to "uncheck" if the date was greater than 2 years old. This changes the attribute in the DB on save without the user knowing. Intended?
      # I'm inclined to leave it checked and change the text to red so that the admins can adjust the attribute manually. The filters will work by considering both
      # the dbs issue date and the dbs qualification fields together.
      twoYearsOld = getToday()
      twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
      dbsExpired = record.dbs_issue_date < twoYearsOld
      if dbsExpired && record.dbs_issue_date != null
        form.find('input[name="prospect[dbs_issue_date]"]').css {color: 'red'}
      else
        form.find('input[name="prospect[dbs_issue_date]"]').css {color: 'unset'}

      bar_manager = questionnaire.bar_management_experience
      if bar_manager == true
        $("#bar_management_experience").prop("checked", true)
      else if bar_manager == false
        $("#bar_management_experience").prop("checked", false)
      else
        bar_manager = ''

      staff_leadership = questionnaire.staff_leadership_experience
      if staff_leadership == true
        $("#staff_leadership_experience").prop("checked", true)
      else if staff_leadership == false
        $("#staff_leadership_experience").prop("checked", false)
      else
        staff_leadership = ''

      festival_event_bar_management = questionnaire.festival_event_bar_management_experience
      if festival_event_bar_management == true
        $("#festival_event_bar_management_experience").prop("checked", true)
      else if festival_event_bar_management == false
        $("#festival_event_bar_management_experience").prop("checked", false)
      else
        festival_event_bar_management = ''

      event_production = questionnaire.event_production_experience
      if event_production == true
        $("#event_production_experience").prop("checked", true)
      else if event_production == false
        $("#event_production_experience").prop("checked", false)
      else
        event_production = ''

    if record.status == 'EMPLOYEE' then form.find('.only-applicants').hide()

#    fillInput(form.node('prospect[qualification_food_health_2]'), record.qualification_food_health_2)
#    fillInput(form.node('prospect[qualification_dbs]'), record.qualification_dbs)

    # fill in 'status' dropdown with statuses which can validly be chosen
    @previousStatus = record.status
    choices =
      APPLICANT:   [['Applicant','APPLICANT'],['Employee','EMPLOYEE'],['Has-Been','HAS_BEEN'],['Deactivated','DEACTIVATED']]
      EMPLOYEE:    [['Employee','EMPLOYEE'],['Sleeper','SLEEPER'],['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
      HAS_BEEN:    [['Employee', 'EMPLOYEE'], ['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
      SLEEPER:     [['Employee','EMPLOYEE'],['Sleeper','SLEEPER'],['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
      DEACTIVATED: [['Employee','EMPLOYEE'],['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
      IGNORED:     [['Employee','EMPLOYEE'],['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
      EXTERNAL:     [['Employee','EMPLOYEE'],['Has-Been','HAS_BEEN'],['Ignored','IGNORED'],['Deactivated','DEACTIVATED'],['External','EXTERNAL']]
    $(form.node('prospect[status]')).html(buildOptions(choices[record.status], record.status)).change()
    @populateCurrentClientChoices(form, record.client_id)

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

  addStatusCallback: () =>
    # This method is also used in GigsView, which doesn't have a 'new form'
    @newForm? && $(@newForm.node('prospect[status]')).change( =>
       $form = @viewport.find('.record-new')
       if $form.node('prospect[status]').value == 'EXTERNAL'
         #  $form.find('.mandatory-internal-only').removeClass('mandatory')
         $form.find('.mandatory-external-only').addClass('mandatory')
         $form.find('.external-only').show()
         $form.find('.internal-only').hide()
       else
         #  $form.find('.mandatory-internal-only').addClass('mandatory')
         $form.find('.mandatory-external-only').removeClass('mandatory')
         $form.find('.external-only').hide()
         $form.find('.internal-only').show()
    )
    $(@editForm.node('prospect[status]')).change( =>
      status = @editForm.node('prospect[status]').value

      $form = @viewport.find('.record-edit')
      if status == 'EXTERNAL'
        $form.find('.mandatory-internal-only').removeClass('mandatory')
        $form.find('.mandatory-external-only').addClass('mandatory')
        $form.find('.external-only').show()
        $form.find('.internal-only').hide()
      else
        $form.find('.mandatory-internal-only').addClass('mandatory')
        $form.find('.mandatory-external-only').removeClass('mandatory')
        $form.find('.external-only').hide()
        $form.find('.internal-only').show()

      if @previousStatus != status
        id = @viewport.find('.record-edit .prospect_id').html()
        prospect = @db.findId('prospects', id)
        if status == 'HAS_BEEN'
          if prospect.status == 'APPLICANT'
            message = "Marking this employee as a has-been will blacklist this applicant and remove their future gigs."
            logNote = "Unsuccessful Interview"
            reason = "Thank you for your time to interview and discuss your skills and attributes. Unfortunately at this point we do not feel we can offer you any suitable work opportunities and therefore will be declining your application to work with us. Good luck in your chosen career."
          else
            message = "Marking this employee as a has-been will blacklist this employee and remove their gig requests and future gigs."
            logNote = "Termination of Employment"
            reason = "Unfortunately you did not demonstrate the required skill level or working ethics during a recent event contact. We therefore currently feel we are unable to offer you future work."

          fnRmv = (params) => ServerProxy.saveChanges('/office/blacklist_employee', $.extend({id: id}, params), Actor(
            requestSuccess: =>
              @requestList.draw()
              @editForm.node('prospect[notes]').value = @db.findId('prospects', id).notes), @db)
          cancelCB = => @editForm.node('prospect[status]').value = @previousStatus
          showReasonDialog('Blacklist', fnRmv, {preMessage: message, logNote: logNote, reason: reason, cancelCB: cancelCB})
        else if status == 'DEACTIVATED'
          bootbox.confirm("Are you sure you want to deactivate #{prospect.first_name} #{prospect.last_name}?", (result) =>
            unless result
              @editForm.node('prospect[status]').value = @previousStatus)
        else if status == 'IGNORED'
          bootbox.confirm("Are you sure you want to ignore #{prospect.first_name} #{prospect.last_name}? You will no longer see #{personalPosessive(prospect.gender)} Gig Requests in the Applied View.", (result) =>
            unless result
              @editForm.node('prospect[status]').value = @previousStatus)
        else if status == 'EMPLOYEE' && @previousStatus == 'APPLICANT'
          params = {
            prospect: {
              first_name: @editForm.node('prospect[first_name]').value,
              last_name: @editForm.node('prospect[last_name]').value,
              date_of_birth: @editForm.node('prospect[date_of_birth]').value,
              email: @editForm.node('prospect[email]').value,
              mobile_no: @editForm.node('prospect[mobile_no]').value,
              gender: @editForm.node('prospect[gender]').value,
              address: @editForm.node('prospect[address]').value,
              city: @editForm.node('prospect[city]').value,
              post_code: @editForm.node('prospect[post_code]').value,
              nationality_id: @editForm.node('prospect[nationality_id]').value
            }
          }
          ServerProxy.sendRequest('/office/status_validate', $.extend({id: id, status: status}, params), Actor(
            requestSuccess: (returned) =>
              if returned.result?.message
                @editForm.node('prospect[status]').value = @previousStatus
                NotificationPopup.requestError(returned)
            requestError: (data) =>
              @editForm.node('prospect[status]').value = @previousStatus
              NotificationPopup.requestError(data)
            @requestList.draw()), @db)
        else
          @previousStatus = @editForm.node('prospect[status]').value)

  addSendMarketingEmailCallback: =>
    $(@editForm.node('prospect[send_marketing_email]')).change(=>
      checkbox = @editForm.node('prospect[send_marketing_email]')
      if checkbox.checked
        checkbox.checked = false
        bootbox.alert("Office Staff cannot re-enable marketing emails. Please have the employee select 'Receive Emails Regarding Upcoming Job Opportunities' in Staff Zone > Profile > Contact Preferences > Email Preferences")
      else
        bootbox.confirm("Are you sure you want to disable marketing emails for this user?", (result) =>
          if result
            checkbox.readOnly = true
          else
            checkbox.checked = true
        )
    )

  buildEventDropdown: (dropdown) ->
    selectedVal = dropdown.val()
    events = @db.queryAll('events', {active: true}, 'name')
    options = buildOptions([['','']].concat(events.map((e) -> [e.name, e.id])), parseInt(selectedVal,10))
    dropdown.html(options)

  buildCityDropdown: (region_id) ->
    prospect = @db.queryAll('prospects', {region_id: region_id}) if region_id != null
    prospect = @db.queryAll('prospects') if region_id == ''
    city_dropdown = @viewport.find('.filter-bar select[name="city"]')
    filterd_prospect = prospect.filter((prs) -> prs.city != null && !(prs.status in ['SLEEPER', 'IGNORED', 'DEACTIVATED', 'HAS_BEEN', 'APPLICANT']) )
    filterd_prospect_name = (x.city for x in filterd_prospect)
    filterd_prospect_name = filterd_prospect_name.sort()
    removeDuplicates = (ar) ->
      if ar.length == 0
        return []
      res = {}
      res[ar[key]] = ar[key] for key in [0..ar.length-1]
      value for key, value of res
    options = buildOptions([['','']].concat(removeDuplicates(filterd_prospect_name).map((city) -> [city, city])))
    city_dropdown.html(options)

  updateDistanceDropdown: (event_dropdown) =>
    dist_dropdown = @viewport.find('.filter-bar select[name="distance"]')
    dist_dropdown.empty()
    dist_dropdown.append(new Option('',''))
    event_id   = event_dropdown.find('option:selected').val()
    if event_id?
      for option in [['< 5', '0,5'],['< 10','0,10'],['< 20','0,20'],['< 30','0,30'],['< 40','0,40'],['< 50','0,50'],['5 - 10','5,10'],['10 - 20','10,20'],['20 - 30','20,30'],['30 - 40','30,40'],['40 - 50','40,50']]
        dist_dropdown.append(new Option(option[0], "#{event_id},#{option[1]}"))

  rejectPhoto: =>
    id = @viewport.find('.record-edit .prospect_id').html()
    ServerProxy.saveChanges('/office/reject_photo', {id: id}, Tee(NotificationPopup, Actor(
      requestSuccess: (returned) =>
        @viewport.find('.prospect_photo').attr('src', "/prospect_photo/#{id}?"+ new Date().getTime()))), @db)
    false # preventDefault && stopPropagation

window.TeamView = TeamView
