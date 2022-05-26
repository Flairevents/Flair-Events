class BulkInterviewsView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Bulk Interviews'
    @columns = [
      {id:"name",               name:"Name"},
      {id:"venue",              name:"Venue"},
      {id:"positions",          name:"Positions"}
      {id:"date_start",         name:"Week of",  type:"date"},
      {id:"target_region_name", name:"Region", virtual:true},
      {id:"event_names",        name:"Events"},
      {id:"interview_type",     name:"Type"},
      {id:"status",             name:"Status"}
    ]

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)

    bulkInterviewBuilder = (bulk_interview) =>
      region_name = window.Regions[bulk_interview.target_region_id]
      [
        bulk_interview.name,
        bulk_interview.venue,
        bulk_interview.positions,
        printDate(bulk_interview.date_start),
        region_name,
        bulk_interview.event_names,
        (if bulk_interview.interview_type == 'ONLINE' then 'Telephone/Online' else 'In Person'),
        (if bulk_interview.status == 'NEW' then "<span class='red-text--bold'>"+bulk_interview.status+"</span>" else bulk_interview.status)
      ]

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'bulk_interviews', @columns, bulkInterviewBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_bulk_interview', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      select: (data) => @select(data)
      deselect: => @commandBar.disableCommands('edit', 'duplicate', 'delete', 'upload')
      activate: (data) => @activate(data)
      clean: => @clean()
      dirty: => @dirty()))

    @table.pageSize(18)
    @table.sortOnColumn('date_start', true)

    @map = new MapView(@viewport.find('.map-view'), @)
    @map = new QueryMap(@map, @db, 'bulkInterviews')

    @shownSubview = 'table'

    fillInEditForm = (form, record) =>
      fillInput(form.node('bulk_interview[name]'), record.name)
      fillInput(form.node('bulk_interview[venue]'), record.venue)
      fillInput(form.node('bulk_interview[positions]'), record.positions)
      fillInput(form.node('bulk_interview[note_for_applicant]'), record.note_for_applicant)
      fillInput(form.node('bulk_interview[address]'), record.address)
      fillInput(form.node('bulk_interview[city]'), record.city)
      fillInput(form.node('bulk_interview[directions]'), record.directions)
      fillInput(form.node('bulk_interview[post_code]'), record.post_code)
      fillInput(form.node('bulk_interview[date_start]'), printDate(record.date_start))
      fillInput(form.node('bulk_interview[date_end]'), printDate(record.date_end))
      fillInput(form.node('bulk_interview[target_region_id]'), record.target_region_id)
      form.find('.bulk_interview_photo').attr('src', if record.photo? then '/bulk_interview_photos/'+record.photo+'?force_refresh='+Math.random() else '')
      fillInput(form.node('bulk_interview[interview_type]'), record.interview_type)
      fillInput(form.node('bulk_interview[id]'), record.id)

      # fill in 'status' dropdown with statuses which can validly be chosen for this Event
      choices = {
        NEW:  [['New','NEW'],['Open','OPEN']],
        OPEN: [['Open','OPEN'], ['Finished', 'FINISHED']],
        FINISHED: [['Finished', 'FINISHED']]}
      form.node('bulk_interview[status]').innerHTML = buildOptions(choices[record.status], record.status)

      @populateEventChoices(form, record)

    fillInNewForm = (form) =>
      form.node('bulk_interview[status]').innerHTML = buildOptions([['New', 'NEW']], 'NEW')
      @populateEventChoices(form, null)

    @editForm = new TinyMceForm(@viewport.find('.record-edit #bulkInterview-details'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm, @viewport.find('.record-edit'))
    @newForm  = new TinyMceForm(@viewport.find('.record-new'), @, fillInNewForm)
    @newForm  = new SlidingForm(@newForm)

    interviewBlockColumns = [
      {id: 'id',          name: 'ID',             hidden: true},
      {id: 'day_of_week', name: 'Day',            sortable: false, virtual: true},
      {id: 'date',        name: 'Date',           sortable: false, type: 'date'},
      {name: 'Morning (10am - 1pm)'},
      {name: 'Afternoon (12:30am - 4pm)'},
      {name: 'Evening (4pm - 7pm)'},
      {name: 'Delete', sortable: false}]

    interviewBlockRowBuilder = (block) =>
      if block.id < 0
        delete_link = ''
      else
        delete_link = $("<a style='color:red' href='javascript:void(0)'>X</a>")
        delete_link.click(=> ServerProxy.sendRequest("/office/delete_interview_block/" + block.id, {}, ErrorOnlyPopup, @db) if block.id != -1)
      
      check_morning = ""
      disable_morning = ""
      if block.is_morning == true
        check_morning = "checked='checked'"
      else
        disable_morning = "disabled='disabled'"
      
      check_afternoon = ""
      disable_afternoon = ""
      if block.is_afternoon == true
        check_afternoon = "checked='checked'"
      else
        disable_afternoon = "disabled='disabled'"
      
      check_evening = ""
      disable_evening = ""
      if block.is_evening == true
        check_evening = "checked='checked'"
      else
        disable_evening = "disabled='disabled'"
      
      # get number of interviews
      if block.is_morning == true || block.is_afternoon == true || block.is_evening == true
        data = $.ajax({url: "/office/get_no_of_interviews", method: 'GET', data: {interview_block_id: block.id}, dataType: 'json', cache: false, async: false})
          .done((data) =>
            return data
          )
        morning_interviews = data.responseJSON.morning_interviews
        afternoon_interviews = data.responseJSON.afternoon_interviews
        evening_interviews = data.responseJSON.evening_interviews

        if block.is_morning == true
          $("##{block.id}_morning_interview").html "#{morning_interviews} bookings"
        if block.is_afternoon == true
          $("##{block.id}_afternoon_interview").html "#{afternoon_interviews} bookings"
        if block.is_evening == true
          $("##{block.id}_evening_interview").html "#{evening_interviews} bookings"
      else
        morning_interviews = block.morning_interviews
        afternoon_interviews = block.afternoon_interviews
        evening_interviews = block.evening_interviews

      [
        buildHiddenInput('bulk_interview_id', block.bulk_interview_id),

        dayOfWeek(block.date),

        buildTextInput({name: "[interviewBlocks][" + block.id + "][date]", value: printDate(block.date), otherHtml: "placeholder='DD/MM/YY' readonly='readonly'", class: 'readonly'}),

        "<input type='checkbox' style='width:fit-content;margin-right:20px;margin-left:10px;' name='[interviewBlocks][" + block.id + "][is_morning]' value=1 id='morning'" + check_morning + ">" + buildTextInput({name: "[interviewBlocks][" + block.id + "][morning_applicants]", value: block.morning_applicants, otherHtml: "style='width: 100px;' id='morning_applicants'" + disable_morning}) + if block.is_morning == true then "<span style='margin-left: 15px;' id='#{block.id}_morning_interview'>" + morning_interviews + " bookings</span>" else "",

        "<input type='checkbox' style='width:fit-content;margin-right:20px;margin-left:10px;' name='[interviewBlocks][" + block.id + "][is_afternoon]' value=1 id='afternoon'" + check_afternoon + ">" + buildTextInput({name: "[interviewBlocks][" + block.id + "][afternoon_applicants]", value: block.afternoon_applicants, otherHtml: "style='width: 100px;' id='afternoon_applicants'" + disable_afternoon}) + if block.is_afternoon == true then "<span style='margin-left: 15px;' id='#{block.id}_afternoon_interview'>" + afternoon_interviews + " bookings</span>" else "",

        "<input type='checkbox' style='width:fit-content;margin-right:20px;margin-left:10px;' name='[interviewBlocks][" + block.id + "][is_evening]' value=1 id='evening'" + check_evening + ">" + buildTextInput({name: "[interviewBlocks][" + block.id + "][evening_applicants]", value: block.evening_applicants, otherHtml: "style='width: 100px;' id='evening_applicants'" + disable_evening}) + if block.is_evening == true then "<span style='margin-left: 15px;' id='#{block.id}_evening_interview'>" + evening_interviews + " bookings</span>" else "",

        delete_link
      ]

    @interviewBlocksTable = new EditableStaticListView(@db, @viewport.find('#bulkInterview-blocks'), 'interview_blocks', interviewBlockColumns, interviewBlockRowBuilder, Actor(
      save: (args) =>
        @saveChanges('/office/update_interview_blocks', args.data, args.actor)
      clean: => @clean()
      dirty: => @dirty()))
    @interviewBlocksTable.filter({filters: {bulk_interview_id: 0}}) ## Don't load anything initially

    @displayedTab = 'bulkInterview-details'
    @viewport.find('.record-edit .slideover-tabs a').click((bulk_interview) =>
      bulk_interview.preventDefault()
      link   = $(bulk_interview.target)
      newTab = link.attr('href').slice(1)
      if newTab != @displayedTab
        @tryToSave(=>
          @displayedTab = newTab
          link.tab('show')))

    add_block_dropdown = @viewport.find('.addblock-dropdown')

    [['Monday', 0], ['Tuesday', 1], ['Wednesday', 2], ['Thursday', 3], ['Friday', 4], ['Saturday', 5]].forEach (day) =>
      option = $('<li><a href="#">' + escapeHTML(day[0]) + '</a></li>')
      option.click =>
        @addBlock(day[1]);
      add_block_dropdown.append(option)

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

    # apply default 'Upcoming' filter
    @filter({filters: @filterBar.selectedFilters()})

    @db.onUpdate('interview_blocks', =>
      @interviewBlocksTable.draw()
      # This 'markClean' is problematic...
      # If the user was in the middle of editing a record when new data comes,
      #   the record he was editing is 'marked clean' and won't be auto-saved!
      @interviewBlocksTable.markClean()
      @interviewBlocksTable.sortOnColumn('date', true))
    @db.onUpdate('bulk_interviews', => @redraw())

  draw: ->
    if @shownSubview == 'table'
      @table.draw()
    else
      @map.draw()

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

  addBlock: (dayOffset) ->
    dateString = @editForm.node('bulk_interview[date_start]').value
    bulk_interview_id = @editForm.node('bulk_interview[id]').value
    date = addDays(stringToDate(dateString, "dd/MM/yyyy", "/"), dayOffset)
    @interviewBlocksTable.addRow({bulk_interview_id: bulk_interview_id, id: -1, day_of_week: dayOfWeek(date), date: date, time_type: '', time_start: '', time_end: '', number_of_applicants: '' })

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @interviewBlockForm.stopEditing()
        @viewport.find('.record-edit a[href="#bulkInterview-details"]').tab('show')
        @displayedTab = 'bulkInterview-details'
      @newForm.newRecord())

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editRecord(record))

  revert: ->
    if @editForm.in()
      switch @displayedTab
        when 'bulkInterview-details'    then @editForm.revert()
        when 'bulkInterview-blocks'
          @bulkInterviewTable.revert()
    else if @newForm.in()
      @newForm.revert()

  deleteRecord: ->
    url = if @editForm.in()
     switch @displayedTab
       when 'bulkInterview-blocks'
         if (record = @interviewBlocksTable.selectedRecord()) && record.id != -1
           '/office/delete_interview_block/' + record.id
       when 'bulkInterview-details'
         if record = @table.selectedRecord()
           '/office/delete_bulk_interview/' + record.id
    else if record = @table.selectedRecord()
      '/office/delete_bulk_interview/' + record.id

    ServerProxy.sendRequest(url, {}, ErrorOnlyPopup, @db)

  uploadPhoto: ->
    @viewport.find('.popover form').fileupload({
      url: '/office/upload_bulk_interview_photo/' + @table.selectedRecord().id,
      datatype: 'json',
      add:  (e, data) =>
        @viewport.find('.progress').show(0)
        data.context = data.files
        data.submit()
        @viewport.find('.command-upload').popover('hide')
      done: (e, data) =>
        result = data.result
        if result.status == 'ok'
          for file in data.context
            notification = $("<span class='file-finished'>Finished " + escapeHTML(file.name) + "</span>")
            @viewport.find('.upload-notification').append(notification)
            setTimeout((-> notification.fadeOut(1000, -> notification.remove())), 4000)
          if result.tables?
            @db.updateData(result)
        else if result.status == 'error'
          NotificationPopup.showPopup('error', result.message) if result.message?
        @viewport.find('.progress').hide(0)
        @viewport.find('.progress .progress-bar').css('width', '0px')
      fail: (e, data) =>
        for file in data.context
          notification = $("<span class='file-failed'>" + escapeHTML(file.name) + " failed</span>")
          @viewport.find('.upload-notification').append(notification)
          setTimeout((-> notification.fadeOut(1000, -> notification.remove())), 4000)
        @viewport.find('.progress').hide(0)
        @viewport.find('.progress .progress-bar').css('width', '0px')
      progressall: (e, data) =>
        progress = parseInt(data.loaded / data.total * 100, 10)
        @viewport.find('.progress .progress-bar').css('width', progress+'%')
    })

  clearFilters: ->
    @filterBar.clearFilters()
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @map.setFilters(data.filters)
    if @shownSubview == 'table'
      @table.draw()
    else
      @map.draw()

  sort: (data) ->
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.sortOnColumn(data.column, data.ascend)
    @table.draw()

  page: (data) ->
    @table.setPage(data.page)
    @table.setOffset((data.page-1) * @table.pageSize())
    @table.deselectRow()
    @table.draw()

  select: (data) ->
    if data.index?
      @table.selectRow(data.index)
    else
      @table.selectRecord(data.record)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=> @editRecord(data.record))
    if coord = coordinatesForRecord(data.record)
      @map.centerOnPoint(coord[0], coord[1])

  activate: (data) ->
    if data.index?
      @table.selectRow(data.index)
    else
      @table.selectRecord(data.record)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#bulkInterview-details"]').tab('show')
        @displayedTab = 'bulkInterview-details')
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editRecord(data.record))
    else
      @editRecord(data.record)

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#bulkInterview-details"]').tab('show')
        @displayedTab = 'bulkInterview-details'
      else if @newForm.in()
        @newForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
      @viewport.find('.record-edit a[href="#bulkInterview-details"]').tab('show')
      @displayedTab = 'bulkInterview-details'
    else if @newForm.in()
      @newForm.stopEditing()

  saveAll: ->
    if @newForm.in()
      #This is called when a new form is saved.
      @tryToSave(=>
        @newForm.stopEditing())
      #If we had a way to get the selected record, we'd open the edit form here.
    else
      @tryToSave(-> null)

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in()
      switch @displayedTab
        when 'bulkInterview-blocks'     then @interviewBlocksTable.save(actor)
        when 'bulkInterview-details'
          if @editForm.isDirty()
            @editForm.saveRecord('/office/update_bulk_interview/', @db, actor, 'bulk_interview')
          else
            callback()
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_bulk_interview/', @db, actor, 'bulk_interview')
    else
      callback()

  saveChanges: (url, data, actor) ->
    ServerProxy.saveChanges(url, data, Actor(
      requestSuccess: (returned) ->
        actor.msg('saved', {sent: data, result: returned.result})
      requestError: (returned) ->
        actor.msg('notsaved', {sent: data, result: returned.result})
      requestFailure: ->
        actor.msg('notsaved', {sent: data})), @db)

  dirty: ->
    @commandBar.enableCommand('revert')
  clean: ->
    @commandBar.disableCommand('revert')

  rowSelected: ->
    @commandBar.enableCommands('edit', 'duplicate', 'delete', 'upload')

  editRecord: (record) ->
    @interviewBlocksTable.filter({filters: {bulk_interview_id: record.id}})
    @interviewBlocksTable.deselectRow()
    @interviewBlocksTable.draw()
    @editForm.node('bulk_interview[id]').value = record.id
    @editForm.editRecord(record)

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

  populateEventChoices: (form, record) =>
    options = []
    dropdown = form.node('bulk_interview[target_region_id]')
    region_name = if dropdown.selectedIndex < 0 then '' else dropdown.options[dropdown.selectedIndex].text
    filters = {active: true}
    filters['region_name'] = region_name if region_name && region_name.toUpperCase() != 'ALL'
    for event in @db.queryAll('events', filters, 'date_start')
      options.push {text: "#{event.name}", id: event.id}

    select2 = $(form.node('bulk_interview_events[]'))
    select2.html("")
    for option in options
      select2.append($('<option></option>').attr('value', option.id).html(option.text))

    if record
      event_ids = (record.event_id for record in @db.queryAll('bulk_interview_events', {bulk_interview_id: record.id}))
      select2.val(event_ids)

    select2.change()

    $(form.node('bulk_interview[target_region_id]')).change( =>
      selected = form.node('bulk_interview_events[]').value
      @populateEventChoices(form, record)
      form.node('bulk_interview_events[]').value = selected)

window.BulkInterviewsView = BulkInterviewsView
