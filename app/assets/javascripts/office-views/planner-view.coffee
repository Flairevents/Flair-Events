class PlannerView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Planner'
    @tasksWindow = null
    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar  = new FilterBar(@viewport.find('.filter-bar'), @)
    @officersLoaded = false

    @columns = [
      {name: 'Due Date', id: 'due_date'},
      {name: 'Event',    id: 'event_id'},
      {name: 'Done?',    id: 'completed', type: 'boolean'},
      {name: 'Task',     id: 'task' , changes_with: ['task', 'completed']},
      {name: 'W2Live',   id: 'weeks_to_live', virtual: true}
      {name: 'Notes',    id: 'notes'},
      {name: 'Done?',    id: 'task_completed', type: 'boolean'},
      {name: 'Task',     id: 'additional_notes'},
      {name: 'Who',      id: 'officer_id'},
      {name: '2nd Who',      id: 'second_officer_id'},
    ]

    @eventTaskListBuilder = (event_task) =>
      $date_field = $("<input type='text' class='form-control date-field' name='[event_tasks][" + event_task.id + "][due_date]' value='" + printDateWithDOW(event_task.due_date) + "' placeholder='DD/MM/YYYY'></input>")
      setUpDatepicker($date_field, 'D dd/mm/yy')
      fillDateInput($date_field, (event_task.due_date || ''))
      officerOptions = EventsView::getActiveOperationalManagerOptions.call(@, event_task.officer_id)
      secondOfficerOptions = EventsView::getActiveOperationalManagerOptions.call(@, event_task.second_officer_id)
      event = @db.findId('events', event_task.event_id);
      if event
        countdown = getEventWeekCountdown(event.date_start, event_task.due_date)
      [$date_field,
        event?.name || '',
        "<input type='hidden' value='0' name='[event_tasks][#{event_task.id}][completed]'><input type='checkbox' class='event-task-checkbox' name='[event_tasks][" + event_task.id + "][completed]'" + (if event_task.completed then " checked='checked'" else "") + ">",
       (if event_task.completed then "<span class='hilite'>#{event_task.task || 'Custom'}</span>" else event_task.task || 'Custom'),
       countdown || ''
       [buildTextInput({name: "[event_tasks][" + event_task.id + "][notes]", value: event_task.notes}),
         ($td) =>
           $td.find('input').attr('title', event_task.notes).tooltip('fixTitle') if event_task.notes && event_task.notes.length > 35
       ],
       "<input type='hidden' value='0' name='[event_tasks][#{event_task.id}][task_completed]'><input type='checkbox' class='event-task-checkbox' name='[event_tasks][" + event_task.id + "][task_completed]'" + (if event_task.task_completed then " checked='checked'" else "") + ">",
       buildTextInput({name: "[event_tasks][" + event_task.id + "][additional_notes]", value: event_task.additional_notes}),
       buildSelect({name: '[event_tasks][' + event_task.id + '][officer_id]', options: officerOptions, selected: event_task.officer_id, class: 'event-task-officer-dropdown'})
       buildSelect({name: '[event_tasks][' + event_task.id + '][second_officer_id]', options: [['','']].concat(secondOfficerOptions), selected: event_task.second_officer_id, class: 'event-task-second-officer-dropdown'})
      ]

    eventTaskListActor = Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_event_tasks', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})
        ), @db)
      activate: (data) => @activate(data)
      select: (data) => @rowSelected()
      deselect: => @rowDeselected())

    @rowStyler = (tr, i) ->
      $tr = $(tr)
      $tr.removeClass('tr-even')
      $tr.removeClass('tr-odd')
      $tr.addClass(dayOfWeekClass(parseDate($tr.find('.date-field').val())))

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'event_tasks', @columns, @eventTaskListBuilder, eventTaskListActor, { saveOnChange: true, rowStyler: @rowStyler })
    @table.pageSize(18)
    @table.sortOnColumn('event_id', true)
    @tablePopup = null;

    @viewport.find('.refresh-data').click(=> @db.refreshData())

    @viewport.on('keydown', (e) =>
      switch e.which
        when 33 # page up
          if @shownSubview == 'hired'
            @hiredView.prevPage()
          else
            @appliedView.prevPage()
          false
        when 34 # page down
          if @shownSubview == 'hired'
            @hiredView.nextPage()
          else
            @appliedView.nextPage()
          false
    )

    @reportDownloader = new ReportDownloader(@table)
    @reportDialog = new ReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new ReportMenu(@viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    @db.onUpdate(['event_tasks', 'officers'], => @redraw())
    @db.onUpdate('events', =>
      @updateEventControls()
      #@updateTaxWeekFilter()
    )
    @db.onUpdate('event_task_templates', => @updateTaskFilterDropdown())
    @db.onUpdate('officers', =>
      @updateOfficerDropdowns(@viewport.find('.filter-bar select[name="officer_id"], select[name="event_task[officer_id]"]'))
      @updateSecondOfficerDropdowns(@viewport.find('.filter-bar select[name="second_officer_id"], select[name="event_task[second_officer_id]"]'))
      if !@officersLoaded  && window.currentOfficerRole == 'staffer'
        @officerFilterDropdown.val(window.currentOfficerId)
        @officersLoaded = false
        @filter({filters: @filterBar.selectedFilters()})
    )
    @db.onUpdate('event_tasks', => @updateTaxWeekFilterDropdown())

    @events = []
    @eventPicker = @viewport.find('.filter-bar input[name="event_picker"]')
    @eventPicker.on 'input', ->
      if $(this).val() == ''
        $('.event-stats-row td').html ''
      else
        events = window.db.queryAll('events', {name: $(this).val()})
        if events.length > 0
          event = events[0]
          $('td.event-need').html event.staff_needed || 0
          staff_needed_for_assignments = event.staff_needed_for_assignments['needed_staff'] || 0
          $('td.event-assigned').html (event.n_gig_assignments['tax_week'] || 0) + ' / ' + (staff_needed_for_assignments || 0)
          $('td.event-hired').html event.n_active_gigs + event.additional_staff || 0
          $('td.event-required').html event.n_gig_requests || 0
          $('td.event-spare').html event.n_gig_requests_spare || 0
          $('td.event-app').html event.n_gig_requests_applicant || 0

          $('td.event-dates').html printSortedEventDates(event.event_dates['tax_week_id'])
          $('td.event-total-weeks').html getEventWeekCountdown(event.date_end, getToday()) || ''
          eventSizeName = window.db.findId('event_sizes', event.size_id)?.name || ""
          $('td.event-plan-size').html eventSizeName || ''
        else
          $('.event-stats-row td').html ''
    @eventPicker.autocomplete({
      source: [],
      select: (e,ui) =>
        @eventPicker.val(ui.item.value)
        @filter({filters: @filterBar.selectedFilters()})
        event = window.db.queryAll('events', {name: ui.item.value})[0]
        $('td.event-need').html event.staff_needed || 0
        staff_needed_for_assignments = event.staff_needed_for_assignments['needed_staff'] || 0
        $('td.event-assigned').html (event.n_gig_assignments['tax_week'] || 0) + ' / ' + (staff_needed_for_assignments || 0)
        $('td.event-hired').html event.n_active_gigs + event.additional_staff || 0
        $('td.event-required').html event.n_gig_requests || 0
        $('td.event-spare').html event.n_gig_requests_spare || 0
        $('td.event-app').html event.n_gig_requests_applicant || 0

        $('td.event-dates').html printSortedEventDates(event.event_dates['tax_week_id'])
        $('td.event-total-weeks').html getEventWeekCountdown(event.date_end, getToday()) || ''
        eventSizeName = window.db.findId('event_sizes', event.size_id)?.name || ""
        $('td.event-plan-size').html eventSizeName || ''
    })

    @clientPicker = @viewport.find('.filter-bar input[name="client_picker"]')
    @clientPicker.autocomplete({
      source: [],
      select: (e,ui) =>
        @clientPicker.val(ui.item.value)
        @filter({filters: @filterBar.selectedFilters()})
    })

    @activeCheckbox = @viewport.find('.filter-bar input[name="active_only"]')
    @activeCheckbox.change(=> @updateEventControls())

    @taxWeekFilterDropdown = @viewport.find('.filter-bar select[name="tax_week_id"]')
    @officerFilterDropdown = @viewport.find('.filter-bar select[name="officer_id"]')
    @completedFilterDropdown = @viewport.find('.filter-bar select[name="completed"]')

    @newEventDropdown = @viewport.find('.record-new select[name="event_task[event_id]"]')
    @editEventDropdown = @viewport.find('.record-edit select[name="event_task[event_id]"]')
    @newTaskDropdown = @viewport.find('.record-new select[name="event_task[template_id]"]')
    @editTaskDropdown = @viewport.find('.record-edit select[name="event_task[template_id]"]')
    @newTaskNotes = @viewport.find('.record-new textarea[name="event_task[notes]"]')
    @editTaskNotes = @viewport.find('.record-edit textarea[name="event_task[notes]"]')

    @newEventDropdown.change(=> @updateTaskDropdown(@newEventDropdown, @newTaskDropdown))
    @editEventDropdown.change(=> @updateTaskDropdown(@editEventDropdown, @editTaskDropdown))
    @newTaskDropdown.change(=> @updateTaskNotes(@newTaskDropdown, @newTaskNotes))
    @editTaskDropdown.change(=> @updateTaskNotes(@editTaskDropdown, @editTaskNotes))

    autosize(@viewport.find('.record-new textarea'))
    fillInNewForm = ($form) =>
      @updateEventDropdown(@newEventDropdown)
      @updateNewOfficeField()
      @updateNewEventField()
      autosize.update($form.find('textarea'))
    @newForm  = new TinyMceForm(@viewport.find('.record-new'), @, fillInNewForm)
    @newForm  = new SlidingForm(@newForm)

    autosize(@viewport.find('.record-edit textarea'))
    fillInEditForm = ($form, record) =>
      @updateEventDropdown(@editEventDropdown)
      @updateOfficerDropdowns($form.find('select[name="event_task[officer_id]"]'), record.officer_id)
      @updateSecondOfficerDropdowns($form.find('select[name="event_task[second_officer_id]"]'), record.second_officer_id)
      autosize.update($form.find('textarea'))
      fillInput($form.node('event_task[event_id]'), record.event_id)
      @updateTaskDropdown(@editEventDropdown, @editTaskDropdown)
      fillInput($form.node('event_task[officer_id]'), record.officer_id)
      fillInput($form.node('event_task[second_officer_id]'), record.second_officer_id)
      fillInput($form.node('event_task[template_id]'), record.template_id)
      fillInput($form.node('event_task[due_date]'), printDateWithDOW(record.due_date))
      fillInput($form.node('event_task[notes]'), record.notes)
      fillInput($form.node('event_task[completed]'), record.completed)
    @editForm  = new TinyMceForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm  = new SlidingForm(@editForm)

    setUpDatepicker(@viewport.find('input[name="event_task[due_date]"]'), 'D dd/mm/yy')

    @filter({filters: @filterBar.selectedFilters()})

  updateEventControls: () =>
    @updateAvailableEvents()
    @updateEventDropdown(@newEventDropdown)
    @updateEventDropdown(@editEventDropdown)
    @setupEventPicker()
    @setupClientPicker()

  updateAvailableEvents: =>
    filter = {show_in_planner: true, status: 'ACTIVE'}
    if @activeCheckbox.prop('checked')
      filter.has_incomplete_tasks = true
    else
      filter.has_tasks = true
    @events = @db.queryAll('events', filter, 'name')

  setupEventPicker: =>
    currentVal = @eventPicker.val()
    event_names = @events.map((e) -> e.name)
    @eventPicker.autocomplete('option', 'source', event_names)
    if event_names.length == 0 || !event_names.hasItem(currentVal)
      @eventPicker.val('')

  setupClientPicker: =>
    currentVal = @clientPicker.val()
    client_ids = []
    for event in @events
      for client_id in event.client_ids
        client_ids.push(client_id)
    client_names = @db.findIds('clients', client_ids.uniqueItems()).map((client) -> client.name)
    @clientPicker.autocomplete('option', 'source', client_names)
    if client_names.length == 0 || !client_names.hasItem(currentVal)
      @clientPicker.val('')

  updateEventDropdown: ($dropdown) =>
    currentVal = $dropdown.val()
    options = [['None', '']].concat(@events.map((e) -> [e.name, e.id]))
    $dropdown.html(buildOptions(options, currentVal)).change()

  updateNewOfficeField: () =>
    officerValue = @officerFilterDropdown.val()
    # console.log('val', officerValue)
    $('select[name="event_task[officer_id]"] option[value="'+officerValue+'"]').removeAttr 'selected'
    $('select[name="event_task[officer_id]"] option[value="'+officerValue+'"]').attr 'selected', 'selected'

  updateNewEventField: () =>
    if @eventPicker.val() != ''
      eventID = @db.queryAll('events', {name: @eventPicker.val()})[0].id
      $('select[name="event_task[event_id]"] option[value="'+eventID+'"]').attr 'selected', 'selected'

  updateTaskFilterDropdown: =>
    $taskFilterDropdown = @viewport.find('.filter-bar select[name="template_id"]')
    currentVal = $taskFilterDropdown.val()
    options = @db.queryAll('event_task_templates', {}, 'task').map((ett) -> [ett.task, ett.id])
    $taskFilterDropdown.html(buildOptions([['', ''],['Custom', 'Custom']].concat(options), currentVal))

  updateTaskDropdown: ($eventDropdown, $taskDropdown) =>
    currentVal = ''
    options = [['Custom','']]
    unless $eventDropdown.val() == ''
      currentVal = $taskDropdown.val()
      options = options.concat(@db.queryAll('event_task_templates', {}, 'task').map((ett) -> [ett.task, ett.id]))
    $taskDropdown.html(buildOptions(options, currentVal))

  updateOfficerDropdowns: ($dropdowns, officerVal = null) =>
    for dropdown in $dropdowns
      $dropdown = $(dropdown)
      currentVal = if officerVal? then officerVal else $dropdown.val()
      options = EventsView::getActiveOperationalManagerOptions.call(@, currentVal)
      $dropdown.html(buildOptions([['', '']].concat(options), currentVal))

  updateSecondOfficerDropdowns: ($dropdowns, officerVal = null) =>
    for dropdown in $dropdowns
      $dropdown = $(dropdown)
      currentVal = if officerVal? then officerVal else $dropdown.val()
      options = EventsView::getActiveOperationalManagerOptions.call(@, currentVal)
      $dropdown.html(buildOptions([['', '']].concat(options), currentVal))

  updateTaxWeekFilterDropdown: =>
    $taxWeekFilterDropdown = @viewport.find('.filter-bar select[name="tax_week_id"]')
    currentTaxWeekId = getCurrentTaxWeek().id
    currentVal = if @twLoaded? then $taxWeekFilterDropdown.val() else currentTaxWeekId
    @twLoaded = true
    tax_week_ids = @db.queryAll('event_tasks', {due_in_this_or_future_tax_week: true}).map((event_task) => event_task.tax_week_id).concat(currentTaxWeekId).uniqueItems()
    tax_weeks = @db.findIds('tax_weeks', tax_week_ids).sort((a,b) -> if (a.date_start > b.date_start) then 1 else -1)
    options = tax_weeks.map((tax_week) -> [printTaxWeek(tax_week), tax_week.id])
    $taxWeekFilterDropdown.html(buildOptions([['', '']].concat(options), currentVal))
    $taxWeekFilterDropdown.change()

  updateTaskNotes:($dropdown, $notes) =>
    template_id = $dropdown.val()
    if template_id? && template_id != ''
      $notes.val(@db.findId('event_task_templates', parseInt(template_id)).notes)
    else
      $notes.val('')

  draw: ->
    @table.draw()
    @tablePopup.draw() if @tasksWindowOpen()

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

  filter: (data) =>
    data.filters.ignore_canceled_events = true
    data.filters.show_in_planner = true
    delete data.filters.active_only
    if (event_name = data.filters.event_picker)?
      events = @db.queryAll('events', {name: event_name})
      if events.length > 0
        data.filters.event_id = events[0].id
      delete data.filters.event_picker
    if (client_name = data.filters.client_picker)?
      clients = @db.queryAll('clients', {name: client_name})
      if clients.length > 0
        data.filters.client_id = clients[0].id
      delete data.filters.client_picker

    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @table.draw()

    if @tasksWindowOpen()
      @tablePopup.setPage(1)
      @tablePopup.setOffset(0)
      @tablePopup.deselectRow()
      @tablePopup.setFilters(data.filters)
      @tablePopup.draw()

    @filterBar.refreshWidths()

  clearFilters: ->
    @viewport.find('.filter-bar').find('input[name="search"], select').val('')
    @completedFilterDropdown.val('To Do')
    @eventPicker.val('')
    $('.event-stats-row td').html ''

  clearAndApplyFilters: ->
    @clearFilters()
    @filter({filters: @filterBar.selectedFilters()})

  newRecord: ->
    @newForm.newRecord()

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editRecord(record))

  editRecord: (record) ->
    @editForm.editRecord(record)

  close: ->
    if @newForm.in()
      @newForm.stopEditing()
    else if @editForm.in()
      @editForm.stopEditing()

  saveAll: (options) ->
    if @newForm.in()
      @tryToSave(=> @newForm.stopEditing())
    else
      @tryToSave(=>)

  saveAndClose: ->
    @tryToSave(=>
      if @newForm.in()
        @newForm.stopEditing()
      else if @editForm.in()
        @editForm.stopEditing())

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_event_task/', @db, actor, 'event_task')
    else if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_event_task/', @db, actor, 'event_task')
    else
      callback()

  select: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=> @editRecord(data.record))

  activate: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing())
    else if @newForm.in()
      @tryToSave(=>
        @newForm.stopEditing()
        @editRecord(data.record))
    else
      @editRecord(data.record)

  rowSelected: (data) ->
    @commandBar.enableCommands('edit', 'delete', 'revert')

  rowDeselected: (data) ->
    @commandBar.disableCommands('edit', 'delete', 'revert')

  postSlideIn: ->
    if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))
    else if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))

  revert: ->
    if @editForm.in()
      @editForm.revert()
    else
      @table.revert()
      @tablePopup.revert() if @tasksWindowOpen()

  deleteRecord: ->
    if record = @table.selectedRecord()
      ServerProxy.sendRequest('/office/delete_event_task/' + record.id, {}, ErrorOnlyPopup, @db)

  showTasksForEvent: (data) ->
    event = @db.findId('events', parseInt(data.event_id,10))
    @clearFilters()
    @eventPicker.val(event.name)
    @taxWeekFilterDropdown.val(data.tax_week_id).change()
    @filter({filters: @filterBar.selectedFilters()})

  showTasksForOfficer: (data) ->
    officer = @db.findId('officers', parseInt(data.officer_id,10))
    @clearFilters()
    @officerFilterDropdown.val(officer.id)
    @taxWeekFilterDropdown.val(data.tax_week_id).change()
    @filter({filters: @filterBar.selectedFilters()})

  tasksWindowOpen: =>
    @tasksWindow? && !@tasksWindow.closed

  # TODO: This bug occurs in development: Uncaught TypeError: Cannot read property 'defaultView' of null
  # It might be related to the datepicker
  openTasksWindow: =>
    new_window = false
    unless @tasksWindowOpen()
      new_window = true
      @tasksWindow = window.open('/office/tasks_window', 'Tasks', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,width=100,height=100')
    if typeof(@tasksWindow) == 'undefined'
      bootbox.alert("You must unblock popups in order to see the tasks window")
    else
      if new_window
        width = $(window).width()*0.9
        height = $(window).height()*0.9
        @tasksWindow.onload = =>
          eventTaskListActor = Actor(
            save: (data) =>
              ServerProxy.saveChanges('/office/update_event_tasks', data.data, Actor(
                requestSuccess: (returned) ->
                  data.actor.msg('saved', {sent: data.data, result: returned.result})
                requestError: (returned) ->
                  data.actor.msg('notsaved', {sent: data.data, result: returned.result})
                requestFailure: ->
                  data.actor.msg('notsaved', {sent: data.data})
              ), @db))
          @tablePopup = new EditableStaticListView(@db, $(@tasksWindow.document.querySelector('.list-view')), 'event_tasks', @columns, @eventTaskListBuilder, eventTaskListActor, { saveOnChange: true, rowStyler: @rowStyler })
          @tablePopup.sortOnColumn('event_id', true)
          $(@tasksWindow).resize( =>
            height = $(@tasksWindow).height()
            nRows = Math.max(1, Math.floor((height-45)/30))
            @tablePopup.pageSize(nRows)
            @filter({filters: @filterBar.selectedFilters()})
          )
          @tasksWindow.resizeTo(width, height)
      else
        @tablePopup.draw()
      @tasksWindow.focus()

window.PlannerView = PlannerView