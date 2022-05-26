class ApplicantsView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Applicants'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)

    @scannedIdDialog = @viewport.find('.scanned-id-dialog')
    @scannedIdDialog.modal({show: false})
    @scannedIdDialog.find('.approve-id-btn').click(=> @approveIds())
    @scannedIdDialog.find('.reject-id-btn').click(=> @rejectIds())

    @scannedBarLicenseDialog = @viewport.find('.scanned-bar-license-dialog')
    @scannedBarLicenseDialog.modal({show: false})

    @viewport.find('.command-password-reset-link').click(=> @passwordResetLink())
    @viewport.find('.command-unlock-account').click(=> @unlockAccount())
    @viewport.find('.command-view-id').click(=> @showScannedIds())
    @viewport.find('.command-view-bar-license').click(=> @showScannedBarLicense())

    prospectColumns = [
      {name: "<input type='checkbox' id='applicant_bulk_select' class='never-dirty'></input>", sortable: false},
      {id: 'name',                       name: 'Name'},
      {id: 'applicant_status',           name: 'Status'},
      {id: "skills",                     name: 'Skills'},
      {id: 'city',                       name: 'City'},
      {id: 'region_id',                  name: 'Region'},
      {id: 'headquarter',name: 'HQ'},
      {id: 'notes',                      name: 'Notes'},
      {id: 'missed_interview_date',      name: 'MI',         type: 'date'},
      {id: 'left_voice_message',         name: 'VM'},
      {id: 'email_status',               name: 'E-M'},
      {id: 'texted_date',                name: 'TXT'},
      {id: 'bulk_interview_id_and_date', name: 'Interview'},
      {id: 'interview_slot_id',          name: 'Time'},
      {name: 'Type'},
      {id: 'registered',                 name: 'Registered', type: 'date'},
      {id: 'gender',                     name: 'Gender'},
      {id: 'age',                        name: 'Age',        type: 'number'}
    ]

    prospectFormBuilder = (prospect) =>
      bulkInterviewAndDateOptions = @getBulkInterviewAndDateOptions()
      interview_slots = if prospect.bulk_interview_id_and_date? then @getInterviewSlots(prospect.bulk_interview_id_and_date, {open: true}) else []
      interview_slot = if prospect.interview_slot_id? then @db.findId('interview_slots', prospect.interview_slot_id) else ''
      #If the slot is full, it won't appear in the list. Add it back in if selected.
      interview_slots.push(interview_slot) unless interview_slot in interview_slots if interview_slot
      interview_slots.sort(@cmpObjsByStartTime)

      # updated interview v2
      interview_block = @db.findId('interview_blocks', interview_slot.interview_block_id)
      interview_block_options = []
      if interview_block
        if interview_block.is_morning == true
          interview_block_options.push(['Morning', 'MORNING.'+ interview_block.id])
        if interview_block.is_afternoon == true
          interview_block_options.push(['Afternoon', 'AFTERNOON.'+ interview_block.id])
        if interview_block.is_evening == true
          interview_block_options.push(['Evening', 'EVENING.'+ interview_block.id])

        # selected
        interview = @db.findId('interviews', prospect.interview_id)
        selected = interview.time_type + "." + interview.interview_block_id

      preferred_type = []
      preferred_type.push 'In Person' if prospect.prefers_in_person
      preferred_type.push 'Phone'     if prospect.prefers_phone
      preferred_type.push 'Skype'     if prospect.prefers_skype
      preferred_type.push 'Facetime'  if prospect.prefers_facetime

      preferred_time = []
      preferred_time.push 'Morn'       if prospect.prefers_morning
      preferred_time.push 'Aft'     if prospect.prefers_afternoon
      preferred_time.push 'Eve' if prospect.prefers_early_evening
      preferred_time.push 'Mid'       if prospect.prefers_midweek
      preferred_time.push 'Wknd'       if prospect.prefers_weekend
      monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

      hq = ""
      if prospect.headquarter != null
        hq = prospect.headquarter.substr(0, 3)

      flag = prospect.flag_photo
      if flag == null then flag = ""

      avg_rating = prospect.avg_rating
      if avg_rating == null
        avg_rating = 0
      questionnaires = @db.queryAll('questionnaires', {prospect_id: prospect.id})
      skills = ''
      if questionnaires.length > 0
        bar = if questionnaires[0].bar_management_experience == true then 'Bar/' else ''
        staff = if questionnaires[0].staff_leadership_experience == true then 'Staff' else ''
        festival_bar = if questionnaires[0].festival_event_bar_management_experience == true then 'Festival Bar' else ''
        event_production = if questionnaires[0].event_production_experience == true then 'Event Production' else ''
        if staff == '' && bar != ''
          bar = 'Bar'
        skills = "#{bar}#{staff}#{festival_bar}#{event_production}"

      interview = @db.findId('interviews', prospect.interview_id)
      types = ''
      if interview?
        call = if interview.telephone_call_interview == true then 'Call/' else ''
        video = if interview.video_call_interview == true then 'Video' else ''
        if video == '' && call != ''
          call = 'Call'
        types = "#{call}#{video}"

      ["<input type='checkbox' class='select_checkbox never-dirty' value='#{prospect.id}' index='#{prospect.id}' #{(if window.isSelected('applicants', prospect.id) then 'checked=\'checked\'' else '')}</input>",

       "<div style='min-width: 215px'>" + if (prospect.age? && (prospect.age < 18)) then "<img src='/prospect_photo/#{prospect.id}?force_refresh=#{Math.random()}' class='team_photo' >" + "<span class='red-text p-text'><b>"+prospectName(prospect)+"</b></span>" + "<br> <small style='float: left;'>R: " + escapeHTML(avg_rating) + "</small>" + " <small style='float: left; margin-left: 10px;'> #E:" + escapeHTML(prospect.n_gigs) + "</small> " + flag else "<img src='/prospect_photo/#{prospect.id}?force_refresh=#{Math.random()}' class='team_photo' >"  + "<span class='p-text'><b>"+prospectName(prospect)+"</b></span>" +  "<br> <small style='float: left;'>R: " + escapeHTML(avg_rating) + "</small>" + " <small style='float: left; margin-left: 10px;'> #E:" + escapeHTML(prospect.n_gigs) + "</small> " + flag + "</div>",

       prospect.applicant_status,
       prospect.skills,
       prospect.city,
       if prospect.region_id then window.Regions[prospect.region_id] else '',
       hq,
       "<div style='min-width: 190px'>" + [buildTextInput({name: "[prospects][" + prospect.id + "][notes]", value: prospect.notes, style: 'width: 100%;'}),
         ($td) =>
           $td.find('input').attr('title', prospect.notes).tooltip('fixTitle') if prospect.notes && prospect.notes.length > 35
       ] + "</div>",
       if prospect.missed_interview_date then new Date(prospect.missed_interview_date).getDate() + "-" + monthNames[new Date(prospect.missed_interview_date).getMonth()] else "",
       "<input type='checkbox' name='[prospects][" + prospect.id + "][left_voice_message]' " + (if prospect.left_voice_message then "checked='checked'" else "") + " >",
       buildSelect({name: "[prospects][#{prospect.id}][email_status]", options: [['',''],['INTERVIEWS', 'INTERVIEWS'],['EVENT', 'EVENT'],['REQUEST CALL', 'REQUEST CALL'], ['PERSONAL','PERSONAL'], ['FAST TRACK','FAST TRACK']], selected: prospect.email_status}),
       if prospect.texted_date then new Date(prospect.texted_date).getDate() + "-" + monthNames[new Date(prospect.texted_date).getMonth()] else "",
       buildSelect({name: "[interviews][#{prospect.id}][bulk_interview_id_and_date]", options: [['','']].concat(bulkInterviewAndDateOptions), selected: prospect.bulk_interview_id_and_date, class: "bulk-interview-class bulk-interview-and-date-dropdown never-dirty"}),
       buildSelect({name: "[interviews][#{prospect.id}][interview_slot_id]", options: [['','']].concat(interview_block_options), selected: selected, class: "slot-dropdown"}),
       types,
       printDate(prospect.registered),
       prospect.gender,
       prospect.age if prospect.date_of_birth
      ]

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
      page: => @page()),
      { saveOnChange: true })

    @table.sortOnColumn('name', true)
    @table.setFilters({status: 'APPLICANT'})

    @map = new MapView(@viewport.find('.map-view'), @)
    @map = new QueryMap(@map, @db, 'prospects')
    @map.setFilters({status: 'APPLICANT'})

    @shownSubview = 'table'

    autosize(@viewport.find('.record-edit textarea'))
    autosize(@viewport.find('.record-new textarea'))
    @previousStatus = ''
    fillInEditForm = (form, record) =>
      @viewport.find('#applicants-profile').text('Loading...')
      TeamView::fillInEditForm.call(@, form, record)
      $.ajax({url: '/office/fetch_profile/'+record.id, method: 'GET', dataType: 'html', cache: false})
        .done((html) => @viewport.find('#applicants-profile').html(html))
      @viewport.find('#applicants-timesheet-notes').text('Loading...')
      $.ajax({url: '/office/fetch_timesheet_notes/'+record.id, method: 'GET', dataType: 'html', cache: false})
        .done((html) => @viewport.find('#applicants-timesheet-notes').html(html))
    fillInNewForm = (form, record) =>
      TeamView::fillInNewForm.call(@, form, record)
    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    TeamView::addStatusCallback.call(@)
    TeamView::addSendMarketingEmailCallback.call(@)
    @actionList = TeamView::setupActionList.call(@, '#applicant-prospect-action-takens')
    @newForm  = new RecordEditForm(@viewport.find('.record-new'), @, fillInNewForm)
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

    requestColumns = [
      {name: 'Event Name',  id: 'event_name'},
      {name: 'Date',  id: 'date_start', type: 'date'},
      {name: 'Applied Job'},
      {name: 'Linked Skills', id:'skills'},
      {name: 'Size', id: 'size'},
      {name: 'Distance'},
      {name: 'Notes', id: 'notes'},
      {name: 'Hire?',   sortable: false},
      {name: 'Spare', id: 'spare'},
      {name: 'Reject?', sortable: false}
    ]
    gigRequestIds = []
    prospectID = 0
    dates = []
    requestRowBuilder = (gig_request) ->
      if gig_request.prospect_id != prospectID
        gigRequestIds = []
        dates = []
        prospectID = gig_request.prospect_id
        allRequest = window.db.queryAll('gig_requests', {prospect_id: gig_request.prospect_id, gig_id: null}, 'date_start')
        dates = (printDate(x.date_start) for x in allRequest)

      gigRequestIds.push(gig_request.id)
      event = window.db.findId('events', gig_request.event_id)
      prospect = window.db.findId('prospects', gig_request.prospect_id)
      dist = 0
      if (coord1 = coordinatesForRecord(prospect)) && (coord2 = coordinatesForRecord(event))
        dist = distanceBetweenPointsInMiles(coord1, coord2)

      color = ''
      count = (dates.filter (val) => val == printDate(gig_request.date_start)).length
      if count > 1
        color = 'yellow'

      ["<div style='background-color: " + color + ";'> "+ escapeHTML(gig_request.event_name) + " </div>",
       printDate(gig_request.date_start),
       "<div style='min-width: 100px'>#{window.db.findId('jobs', gig_request.job_id).name}</div>",
       "<div style='min-width: 230px'>#{gig_request.skills}</div>",
       gig_request.size,
       dist,
       [buildTextInput({name: "[gig_requests][" + gig_request.id + "][notes]", value: gig_request.notes, style: 'width: 100%;'}),
         ($td) =>
           $td.find('input').attr('title', gig_request.notes).tooltip('fixTitle') if gig_request.notes && gig_request.notes.length > 35
       ],
       "<input type='checkbox' class='hire-checkbox' value='" + gig_request.id + "'>",
       "<input type='checkbox' onclick='ServerProxy.saveChanges(\"/office/set_spare/#{gig_request.id}\", {spare: $(this).is(\":checked\")}, null, window.db)' #{if gig_request.spare then 'checked' else ''}>",
       "<input type='checkbox' class='reject-checkbox' value='" + gig_request.id + "'>"]
    @requestList = new EditableStaticListView(@db, @viewport.find('#applicants-requests'), 'gig_requests', requestColumns, requestRowBuilder, Actor(
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
    @requestList.sortOnColumn('date_start', true)
    @requestList.setFilters({gig_id: null})
    @viewport.find('.hire-btn').click(=>
      @requestList.saveCurrentRow()
      requestIds = $.makeArray(@viewport.find('#applicants-requests .hire-checkbox:checked')).map((check) -> $(check).attr('value'))
      totalRequests = @viewport.find('#applicants-requests .hire-checkbox').length
      if requestIds.length > 0
        message = warningForOtherManagers(requestIds)
        applicantRequestList = @requestList
        myDb = @db
        editForm = @editForm
        if message != ''
          bootbox.confirm({
            message: message,
            buttons: {
              confirm: {
                label: 'Hire Agreed',
              }
            },
            callback:(result) ->
              if result == true
                ServerProxy.saveChanges('/office/create_gigs', {gig_requests: requestIds}, Actor(
                  requestSuccess: (returned) =>
                    if !!returned.result?.deleted?.gig_requests?.length then editForm.node('prospect[status]').value = 'EMPLOYEE'
                    applicantRequestList.draw()), myDb)
          })
        else
          ServerProxy.saveChanges('/office/create_gigs', {gig_requests: requestIds}, Actor(
            requestSuccess: (returned) =>
              console.log(returned)
              if !!returned.result?.deleted?.gig_requests?.length then editForm.node('prospect[status]').value = 'EMPLOYEE'
              @requestList.draw()), @db)
      else
        if totalRequests > 0
          bootbox.confirm('Are you sure you want to hire without any selected gig requests?', (result) ->
            if result
              ServerProxy.saveChanges('/office/hire', {id: $('#applicants-details .prospect_id').html()}, Actor(
                requestSuccess: =>
                  @node('prospect[status]').value = 'EMPLOYEE'
                  @requestList.draw()), @db))
        else
          ServerProxy.saveChanges('/office/hire', {id: $('#applicants-details .prospect_id').html()}, Actor(
            requestSuccess: =>
              @node('prospect[status]').value = 'EMPLOYEE'
              @requestList.draw()), @db))
    @viewport.find('.reject-btn').click(=>
      requestIds = $.makeArray(@viewport.find('#applicants-requests .reject-checkbox:checked')).map((check) -> $(check).attr('value'))
      if requestIds.length > 0
        fnRmv = (params) => ServerProxy.saveChanges('/office/delete_gig_requests', $.extend({gig_requests: requestIds, skip_log: true}, params), Actor(
          requestSuccess: =>
            @requestList.draw()), @db)
        showReasonDialog('Decline', fnRmv, {skip_log: true}))

    @assignEventsDialog = @viewport.find('.multi-assigner')
    @assigner = new MultiAssigner(@assignEventsDialog.find('.modal-body'), @)

    @bulkSMSDialog = @viewport.find('.bulk-sms-dialog')

    @requestedEventDropdown = @viewport.find('.filter-bar select[name="requested_event"]')
    @unrequestedEventDropdown = @viewport.find('.filter-bar select[name="unrequested_event"]')
    @buildEventDropdown(@requestedEventDropdown)
    @buildEventDropdown(@unrequestedEventDropdown)
    @requestedEventDropdown.on('change', @updateDistanceDropdown)
    @unrequestedEventDropdown.on('change', @updateDistanceDropdown)

    @bulkInterviewAndDateFilter = @viewport.find('.filter-bar select[name="bulk_interview_id_and_date"]')
    @buildBulkInterviewAndDateFilterDropdown()
    @bulkInterviewAndDateFilter.on('change', @bulkInterviewAndDateFilterChangeHandler)

    @interviewSlotFilter = @viewport.find('.filter-bar select[name="interview_slot_id"]')

    $(@node('registered_in')).change =>
      if @node('registered_in').value < 0
        @commandBar.disableCommands('bulkdelete')
      else
        @commandBar.enableCommands('bulkdelete')

    @viewport.find('.autozoom').change(=>
      @map.setAutozoom(@viewport.find('.autozoom').is(':checked')))

    @viewport.find('.refresh-data').click(=>
      @db.refreshData())

    @viewport.find('.record-new .photo-area').remove()

    @viewport.on('keydown', (e) =>
      switch e.which
        when 33 # page up
          @table.prevPage()
          false
        when 34 # page down
          @table.nextPage()
          false
    )

    @displayedTab = 'applicants-profile'
    @viewport.find('.record-edit .slideover-tabs a').click((prospect) =>
      prospect.preventDefault()
      link   = $(prospect.target)
      newTab = link.attr('href').slice(1)
      if newTab != @displayedTab
        @tryToSave(=>
          @displayedTab = newTab
          link.tab('show')
          @editForm.refreshForm(@db, 'prospects')))

    @viewport.find(".prospect_reject_photo").click(=> TeamView::rejectPhoto.call(@))

    @bulk_select = $('#applicant_bulk_select')
    @bulk_select.bind('click', @bulkSelectClickHandler)
    @bulk_select.bind('change', @bulkSelectChangeHandler)

    @rebuildEmailTemplateDropdown()

    @db.onUpdate('text_blocks', => @rebuildEmailTemplateDropdown())
    @db.onUpdate('events', =>
      EventsView::updateStatistics()
      @buildEventDropdown(@requestedEventDropdown)
      @buildEventDropdown(@unrequestedEventDropdown))
    @db.onUpdate('gig_requests', =>
      if @editForm.in()
        @requestList.draw()
        @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')'))
    @db.onUpdate('action_takens', =>
      if @editForm.in()
        @actionList.draw()
        @viewport.find('.prospect-action-taken-tab').text('Action Logs (' + @actionList.totalRecords() + ')'))
    @db.onUpdate(['bulk_interviews', 'interview_blocks'], =>
      @buildBulkInterviewAndDateFilterDropdown())
    @db.onUpdate(['prospects', 'interview_blocks', 'interview_slots', 'bulk_interviews'], =>
      EventsView::updateStatistics()
      @redraw())

  ##### TeamView::fillInEditForm calls this routine, so we alias it
  populateCurrentClientChoices: (form, client_id) => TeamView::populateCurrentClientChoices.call(@, form, client_id)

  updateDistanceDropdown: =>
    dist_dropdown = @viewport.find('.filter-bar select[name="distance"]')
    dist_dropdown.empty()
    requestedEventId   = @requestedEventDropdown.find('option:selected').val()
    unrequestedEventId = @unrequestedEventDropdown.find('option:selected').val()
    if (requestedEventId != '') && (unrequestedEventId == '')
      event_id = requestedEventId
    if (requestedEventId == '') && (unrequestedEventId != '')
      event_id = unrequestedEventId
    dist_dropdown.append(new Option('',''))
    if event_id?
      for option in [['< 5','0,5'],['< 10','0,10'],['< 20','0,20'],['< 30','0,30'],['< 40','0,40'],['< 50','0,50'],['5 - 10','5,10'],['10 - 20','10,20'],['20 - 30','20,30'],['30 - 40','30,40'],['40 - 50','40,50']]
        dist_dropdown.append(new Option(option[0], "#{event_id},#{option[1]}"))

  draw: ->
    if @shownSubview == 'table'
      @table.draw()
      @updateRowHandlers()
    else
      @map.draw()

  page: ->
    @updateRowHandlers()

  buildBulkInterviewAndDateFilterDropdown: ->
    @addBulkInterviewAndDatesToDropdown(@viewport.find('.filter-bar select[name="bulk_interview_id_and_date"]'))

  addBulkInterviewAndDatesToDropdown: (dropdown) ->
    $(dropdown).empty();
    $(dropdown).append($('<option></option>').val('').html(''))
    $(dropdown).append($('<option></option>').val(-1).html('None'))
    options = @getBulkInterviewAndDateOptions()
    for option in options
      $(dropdown).append($('<option></option>').val(option[1]).html(option[0]))

  getBulkInterviewAndDateOptions:  ->
    interview_blocks = @db.queryAll('interview_blocks', {current: true})
    interview_blocks.sort(@cmpInterviewBlocks)
    @getBulkInterviewAndDateOptionsFromInterviewBlocks(interview_blocks)

  getBulkInterviewAndDateOptionsFromInterviewBlocks: (interview_blocks) ->
    options = []
    for ib in interview_blocks
      value = "#{ib.bulk_interview_id}_#{printDate(ib.date)}"
      text = "#{printDateDDMM(ib.date)}  #{@db.findId('bulk_interviews', ib.bulk_interview_id).name}"
      options.push([text, value])
    options

  cmpInterviewBlocks: (a,b) =>
    if a.date.getTime() > b.date.getTime()
      return 1
    else if a.date.getTime() < b.date.getTime()
      return -1
    else
      @cmp(@db.findId('bulk_interviews', a.bulk_interview_id).name, @db.findId('bulk_interviews', b.bulk_interview_id).name)

  cmp: (a,b) ->
    ((a == b) ? 0 : ((a > b) ? 1 : -1))

  updateRowHandlers: ->
    rebind(@viewport.find('.bulk-interview-and-date-dropdown'), 'change', @bulkInterviewAndDateDropdownHandler)
    rebind(@viewport.find('.select_checkbox'), 'change', @selectCheckboxHandler)

  saveCurrentRow: =>
    @table.saveCurrentRow()

  bulkInterviewAndDateDropdownHandler: (event) =>
    biad_dropdown = event.target
    slot_dropdown = $(biad_dropdown).parents().eq(1).find('.slot-dropdown')
    $(slot_dropdown).empty()
    @addInterviewSlotsToDropdown(biad_dropdown, slot_dropdown)

  selectCheckboxHandler: (event) =>
    $checkbox = $(event.target)
    id = $checkbox.attr('index')
    if $checkbox.prop('checked') then selectRecord('applicants', id) else deselectRecord('applicants', id)
    n_total_applicants = @getFilteredApplicants.length
    n_selected = nSelected('applicants')

    if n_selected == 0
      @bulk_select.prop('indeterminate', false)
      @bulk_select.prop('checked', false)
    else if n_selected == n_total_applicants
      @bulk_select.prop('indeterminate', false)
      @bulk_select.prop('checked', true)
    else
      @bulk_select.prop('indeterminate', true)
    event.stopPropagation()

  #We don't want this particular header to trigger a sort when clicked on
  bulkSelectClickHandler: (event) =>
    event.stopPropagation()

  bulkSelectChangeHandler: (event) =>
    @bulk_select.prop('indeterminate', false)
    if @bulk_select.prop('checked')
      @viewport.find('.record-list-applicants').find('.select_checkbox').prop('checked', true)
      selectRecord('applicants', applicant.id) for applicant in @getFilteredApplicants()
    else
      @viewport.find('.record-list-applicants').find('.select_checkbox').prop('checked', false)
      clearAllSelected('applicants')

  getFilteredApplicants: () =>
    filters = {}
    filters['status'] = 'APPLICANT'
    @db.queryAll('prospects', filters)

  bulkInterviewAndDateFilterChangeHandler: () =>
    @addInterviewSlotsToDropdown(@bulkInterviewAndDateFilter, @interviewSlotFilter)
    if $(@bulkInterviewAndDateFilter).val() == ''
      $(@interviewSlotFilter).empty()
      $(@interviewSlotFilter).trigger('change')

  addInterviewSlotsToDropdown: (bulkInterviewAndDateDropdown, slot_dropdown, filter={}) =>
    slot_val = $(slot_dropdown).val()
    $(slot_dropdown).empty()
    interview_slots = @getInterviewSlots($(bulkInterviewAndDateDropdown).val(), filter)

    interview_slots.sort(@cmpObjsByStartTime)
    if interview_slots.length > 0
      interview_block = @db.findId('interview_blocks', interview_slots[0].interview_block_id)
      $(slot_dropdown).append($('<option></option>').html(''))
      if interview_block.is_morning == true
        $(slot_dropdown).append($('<option></option>').val('MORNING.' + interview_block.id).html('Morning'))
      if interview_block.is_afternoon == true
        $(slot_dropdown).append($('<option></option>').val('AFTERNOON.' + interview_block.id).html('Afternoon'))
      if interview_block.is_evening == true
        $(slot_dropdown).append($('<option></option>').val('EVENING.' + interview_block.id).html('Evening'))
    interview_slot_ids = interview_slots.map((slot) => slot.id)
    $(slot_dropdown).change() if !interview_slots.map((slot) => slot.id).hasItem(slot_val)
    $(slot_dropdown).val(slot_val)

  getInterviewSlots: (biadString, filter = {}) ->
    interview_slots = []
    if biadString && biadString != '' && biadString != '-1'
      biad = biadString.split "_"
      date = stringToDate(biad[1], "dd/MM/yyyy", "/")
      bulk_interview_id = parseInt(biad[0])
      filter['date'] = date
      filter['bulk_interview_id'] = bulk_interview_id
      filter['open'] = true
      interview_slots = @db.queryAll('interview_slots', filter, 'time_start')
    interview_slots

  toggleSubview: ->
    if @shownSubview == 'table'
      @viewport.find('.list-view, .list-view-only').hide()
      @viewport.find('.map-view, .map-view-only').show()
      if mapWidget = @map.googleMap()
        gmapevt.trigger(mapWidget, 'resize')
      @shownSubview = 'map'
    else
      @viewport.find('.map-view, .map-view-only').hide()
      @viewport.find('.list-view, .list-view-only').show()
      @shownSubview = 'table'

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

  assignEvents: ->
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

  clearFilters: ->
    @filterBar.clearFilters()
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    data.filters['status'] = 'APPLICANT'
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @map.setFilters(data.filters)
    @draw()

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
        @viewport.find('.record-edit a[href="#applicants-details"]').tab('show'))
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editForm.editRecord(data.record))
    else
      @editForm.editRecord(data.record)

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#applicants-details"]').tab('show')
      else if @newForm.in()
        @newForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
      @viewport.find('.record-edit a[href="#applicants-details"]').tab('show')
    else if @newForm.in()
      @newForm.stopEditing()


  postSlideIn: ->
    if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))
    else if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))

  saveAll: ->
    @tryToSave(-> null)

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_prospect/', @db, actor, 'prospect')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_prospect', @db, actor, 'prospect')
    else
      callback()

  showApplicantsForEvent: (data) ->
    @clearFilters()
    @requestedEventDropdown.val(data.event_id)
    @filter({filters: @filterBar.selectedFilters()})

  dirty: ->
  clean: ->

  bulkSMS: ->
    GigsView::bulkSMS.call(@, (@table.allRecords().filter (p) -> p.send_marketing_email), 'Bulk Marketing SMS')

  bulkEmail: ->
    GigsView::bulkEmail.call(@, (@table.allRecords().filter (p) -> p.send_marketing_email), 'Bulk Marketing Email (All)')

  bulkEmailGrouped: ->
    GigsView::bulkEmail.call(@, (@table.allRecords().filter (p) -> p.send_marketing_email), 'Bulk Marketing Email (Groups of 400)', 400)

  bulkEntry: ->
    myDB = @db
    prospectIds = $.makeArray(@viewport.find('.select_checkbox:checked')).map((check) -> $(check).attr('value'))
    if prospectIds.length > 1
      bulkInfo = (params) => ServerProxy.sendRequest('/office/bulk_info_of_applicants', $.extend({prospect_ids: prospectIds}, params), Actor(
          requestSuccess: (data) ->
            $('#applicant_bulk_select').prop 'checked', false
            $('#applicant_bulk_select').prop('indeterminate', false)
            $('.select_checkbox').prop 'checked', false
          requestError: (data) ->
            myDB.refreshData()
            $('#applicant_bulk_select').prop 'checked', false
            $('#applicant_bulk_select').prop('indeterminate', false)
            $('.select_checkbox').prop 'checked', false
      ), myDB)
      bulkEntryForApplicants(bulkInfo)

  rowSelected: (data) ->
    if data.index?
      @table.selectRow(data.index)
    else
      @table.selectRecord(data.record)
    @requestList.setFilters({prospect_id: @table.selectedRecord().id, gig_id: null})
    @requestList.draw()
    @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')')
    @actionList.setFilters({prospect_id: @table.selectedRecord().id})
    @actionList.draw()
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

  buildEventDropdown: (dropdown) ->
    selectedVal = dropdown.val()
    events = @db.queryAll('events', {active: true}, 'name')
    options = buildOptions([['',''],['ANY','ANY']].concat(events.map((e) -> [e.name, e.id])), parseInt(selectedVal,10))
    dropdown.html(options)

  passwordResetLink: ->
    if record = @table.selectedRecord()
      popup=window.open("/office/generate_forgot_password_text?id=#{record.id}")
      popup.focus()
    else
      alert("You must select an applicant first")

  unlockAccount: ->
    if record = @table.selectedRecord()
      ServerProxy.sendRequest('/office/unlock_account', {id: record.id}, NotificationPopup, @db)
    else
      alert("You must select an applicant first")

  numDaysBetweenDates: (d1, d2) ->
    (d1.getTime() - d2.getTime())/(1000 * 60 * 60 * 24)

  applicantThisMonth: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="active_applicant"]').val('THIS_MONTH')
      @filter({filters: @filterBar.selectedFilters()}))

  applicantLastMonth: ->
    @tryToSave(=>
      @clearFilters()
      @viewport.find('.filter-bar select[name="active_applicant"]').val('LAST_MONTH')
      @filter({filters: @filterBar.selectedFilters()}))

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

  cmpObjsByStartTime: (a,b) ->
    if a.time_start < b.time_start
      return -1
    else if a.time_start > b.time_start
      return 1
    else
      return 0

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

window.ApplicantsView = ApplicantsView
