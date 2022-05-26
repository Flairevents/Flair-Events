class LibraryView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Library'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)

    columns = [
      {name: 'Name', id: 'name'},
      {name: 'Filename', id: 'filename'}]
    @listView = new ListView(@db, @viewport, 'library_items', columns, @)
    @listViewHandler = new DefaultListViewHandler(@listView)

    fillInEditForm = (form, record) ->
      form.node('library_item[name]').value = record.name

    @editForm = new SlidingForm(new RecordEditForm(@viewport.find('.record-edit'), @, fillInEditForm))
    @newForm  = new SlidingForm(new RecordEditForm(@viewport.find('.record-new'), @))

    @startUpload = null
    @uploadDone  = null
    @viewport.find('#library-upload').fileupload({
      url: '/office/create_library_item',
      replaceFileInput: false,
      datatype: 'json',
      add:  (e, data) =>
        data.context = data.files
        @startUpload = -> data.submit()
      done: (e, data) =>
        result = data.result
        if result.status == 'ok'
          for file in data.context
            notification = $("<span class='file-finished'>Finished " + escapeHTML(file.name) + "</span>")
            @viewport.find('.upload-notification').append(notification)
            setTimeout((-> notification.fadeOut(1000, -> notification.remove())), 4000)
          if result.tables? || result.deleted?
            @db.updateData(result)
        else if result.status == 'error'
          NotificationPopup.showPopup('error', result.message) if result.message?
        @viewport.find('.progress').hide(0)
        @viewport.find('.progress .progress-bar').css('width', 0)
        @uploadDone.msg('saved', {result: result}) if @uploadDone?
      fail: (e, data) =>
        for file in data.context
          notification = $("<span class='file-failed'>" + escapeHTML(file.name) + " failed</span>")
          @viewport.find('.upload-notification').append(notification)
          setTimeout((-> notification.fadeOut(1000, -> notification.remove())), 4000)
        @viewport.find('.progress').hide(0)
        @viewport.find('.progress .progress-bar').css('width', 0)
        @uploadDone.msg('failed') if @uploadDone?
      progressall: (e, data) =>
        @viewport.find('.progress').show(0)
        progress = parseInt(data.loaded / data.total * 100, 10)
        @viewport.find('.progress .progress-bar').css('width', progress+'%')
    })

    @viewport.on('keydown', (e) =>
      switch e.which
        when 33 # page up
          @listView.prevPage()
          false
        when 34 # page down
          @listView.nextPage()
          false
    )

    @viewport.find('.refresh-data').click(=>
      @db.refreshData())

    @db.onUpdate('library_items', => @redraw())

  draw: -> @listView.draw()

  sort: (data) ->
    @listViewHandler.sort(data)
  page: (data) ->
    @listViewHandler.page(data)
  select: (data) ->
    @listViewHandler.select(data)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=> @editForm.editRecord(@listView.selectedRecord()))
  deselect: ->
    @commandBar.disableCommands('edit', 'delete', 'open')
  activate: (data) ->
    @listViewHandler.activate(data)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=> @editForm.stopEditing())
    else if record = @listView.selectedRecord()
      if @newForm.in()
        @tryToSave(=> @newForm.stopEditing(); @editForm.editRecord(record))
      else
        @editForm.editRecord(record)

  rowSelected: ->
    @commandBar.enableCommands('edit', 'delete', 'open')

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
      @newForm.newRecord())
  editSelectedRecord: ->
    if record = @listView.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editForm.editRecord(record))
  deleteRecord: ->
    if record = @listView.selectedRecord()
      ServerProxy.saveChanges("/office/delete_library_item/"+record.id, {}, NullActor, @db)
  revert: ->
    if @newForm.in()
      @newForm.revert()
    else if @editForm.in()
      @editForm.revert()
  openFile: ->
    if record = @listView.selectedRecord()
      window.open('/office/download_library_file/' + record.id, '_blank')

  clean: ->
    @commandBar.disableCommand('revert')
  dirty: ->
    @commandBar.enableCommand('revert')
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
  saveAll: ->
    @tryToSave(-> null)
  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  tryToSave: (callback) =>
    actor = Actor(
      saved: (data) =>
        callback()
        NotificationPopup.requestSuccess(data)
        @commandBar.disableCommand('revert')
      failed: (data) ->
        NotificationPopup.requestError(data))

    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_library_item/', @db, actor, 'content')
    else if @newForm.in() && @newForm.isDirty()
      if @startUpload?
        @uploadDone = actor
        @startUpload()
    else
      callback()


window.LibraryView = LibraryView