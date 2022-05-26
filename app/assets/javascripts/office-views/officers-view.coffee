class OfficersView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Officers'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar  = new FilterBar(@viewport.find('.filter-bar'), @)

    columns = [
      {id: "name",       name: "Name"},
      {id: "email",      name: "E-mail"},
      {id: "role",       name: "Role"},
      {id: "active_operational_manager", name: "Op Mgr", type: "boolean"},
      {id: "senior_manager", name: "Senior Mgr", type: "boolean"},
      {id: "locked_out", name: "Locked", type: "boolean"}]

    @listView = new ListView(@db, @viewport, 'officers', columns, @)
    @listViewHandler = new DefaultListViewHandler(@listView)

    @listView.sortOnColumn('name', true)
    @listView.setFilters(@filterBar.selectedFilters())

    fillEditForm = (form, record) ->
      if record
        @viewport.find('#officer-session-log').text('Loading...')
        $.ajax({url: '/office/fetch_session_log/' + record.id, method: 'GET', dataType: 'html', cache: false})
          .done((html) => @viewport.find('#officer-session-log').html(html))

        form.find('select option:selected').removeAttr('selected')
        form.find('#officer_first_name').val(record.first_name)
        form.find('#officer_last_name').val(record.last_name)
        form.find('#officer_email').val(record.email)
        form.find('#officer_role option').filter(-> $(this).val() == record.role).prop('selected',true)
        form.find('#officer_active_operational_manager').prop('checked', record.active_operational_manager)
        form.find('#officer_senior_manager').prop('checked', record.senior_manager)
        if record.email == window.currentOfficerEmail
          form.find('.password-edit-field').show(0)
        else
          form.find('.password-edit-field').hide(0)
      else
        form.find('select option:selected').removeAttr('selected')
        form.find('#officer_first_name').val('')
        form.find('#officer_last_name').val('')
        form.find('#officer_email').val('')
        form.find('#officer_role').val('staffer')
        form.find('#officer_active_operational_manager').prop('checked', false)
        form.find('#officer_senior_manager').prop('checked', false)

    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, fillEditForm)
    @editForm = new SlidingForm(@editForm)

    @viewport.find('.refresh-data').click(=> @db.refreshData())

    @viewport.on('keydown', (e) =>
      switch e.which
        when 33 # page up
          @listView.prevPage()
          false
        when 34 # page down
          @listView.nextPage()
          false
    )

    @db.onUpdate('officers', => @redraw())

  draw: ->
    @listView.draw()

  sort: (data) ->
    @listViewHandler.sort(data)
    @commandBar.disableCommands('edit', 'delete', 'lock', 'unlock')
  page: (data) ->
    @listViewHandler.page(data)
    @commandBar.disableCommands('edit', 'delete', 'lock', 'unlock')

  select: (data) ->
    @listViewHandler.select(data)
    @commandBar.enableCommands('edit', 'delete', 'lock', 'unlock')
    if @editForm.in()
      @tryToSave(=> @editForm.editRecord(@listView.selectedRecord()))

  activate: (data) ->
    @listViewHandler.activate(data)
    @commandBar.enableCommands('edit', 'delete')
    if @editForm.in()
      @tryToSave(=> @editForm.stopEditing())
    else if record = @listView.selectedRecord()
      @editForm.editRecord(record)

  newRecord: ->
    @tryToSave(=>
      @viewport.find('.record-edit .password-edit-field').show(0)
      @editForm.newRecord())

  editSelectedRecord: ->
    if record = @listView.selectedRecord()
      @tryToSave(=> @editForm.editRecord(record))

  saveAndClose: ->
    @tryToSave(=> @editForm.stopEditing())

  close: ->
    @editForm.stopEditing()

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  saveAll: ->
    @tryToSave(-> null)

  revert: ->
    @editForm.revert()
  dirty: ->
    @commandBar.enableCommand('revert')
  clean: ->
    @commandBar.disableCommand('revert')

  deleteOfficer: ->
    if record = @listView.selectedRecord()
      ServerProxy.saveChanges('/office/delete_officer/'+record.id, {}, NullActor, @db)

  lockOfficer: ->
    if record = @listView.selectedRecord()
      ServerProxy.saveChanges('/office/lock_officer/'+record.id, {}, NullActor, @db)

  unlockOfficer: ->
    if record = @listView.selectedRecord()
      ServerProxy.saveChanges('/office/unlock_officer/'+record.id, {}, NullActor, @db)

  tryToSave: (callback) ->
    if @editForm.in() && @editForm.isDirty()
      actor = Actor({saved: callback})
      if @editForm.isNewRecord()
        @editForm.saveRecord('/office/create_officer', @db, actor, 'officer')
      else
        @editForm.saveRecord('/office/update_officer/', @db, actor, 'officer')
    else
      callback()

  clearFilters: ->
    @viewport.find('.filter-bar').find('input[name="search"], select').val('')
    @viewport.find('.filter-bar select[name="role"]').val('Active')
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    @listView.setPage(1)
    @listView.setOffset(0)
    @listView.deselectRow()
    @listView.setFilters(data.filters)
    @listView.draw()
    @filterBar.refreshWidths()

window.OfficersView = OfficersView
