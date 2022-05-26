class ContentView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Content'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)

    columns = [
      {name: 'Name', id: 'key'},
      {name: 'Title', id: 'title', type: 'title'},
      {name: 'Content', id: 'contents'},
      {name: 'Status', id: 'status'}
      {name: 'Updated', id: 'updated_at', type: 'date'}]
    @listView = new ListView(@db, @viewport, 'text_blocks', columns, @)
    @listView.rowBuilder((record) ->
      [record.key,
       record.title,
       if record.contents.length > 60
         removeTags(record.contents.slice(0, 60) + '...')
       else
         removeTags(record.contents)
       ,record.status,
       printDate(record.updated_at)
      ])
    @listViewHandler = new DefaultListViewHandler(@listView)

    fillInEditForm = (form, content) =>
      form.node('content[key]').value = content.key
      form.find('#content_updated_at').text(printDate(content.updated_at))
      form.node('content[status]').value = content.status
      form.find('img.thumbnail').prop('src', if content.thumbnail then '/content_thumbnails/'+content.thumbnail else '')
      form.node('content[title]').value = content.title

      if content.type == 'terms'
        form.node('content[status]').value = 'PUBLISHED'
        form.node('content[status]').disabled = true
        form.node('content[key]').value = 'Terms'
        form.node('content[key]').readOnly = true
      else if content.type == 'page'
        form.node('content[status]').disabled = true
        form.node('content[key]').readOnly = true
      else
        form.node('content[status]').disabled = false
        form.node('content[key]').readOnly = false

      if content.type == 'news'
        form.find('.thumbnail-row').show()
        form.find('.title-row').show()
      else
        form.find('.thumbnail-row').hide()
        form.find('.title-row').hide()

    @editForm = new TinyMceForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    @newForm  = new TinyMceForm(@viewport.find('.record-new'), @)
    @newForm  = new SlidingForm(@newForm)

    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)
    @listView.setFilters(@filterBar.selectedFilters())
    @selectedContentType = @filterBar.selectedFilters().type

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

    @db.onUpdate('text_blocks', => @redraw())

  draw: ->
    @listView.draw()

  sort: (data) ->
    @listViewHandler.sort(data)
  page: (data) ->
    @listViewHandler.page(data)
  select: (data) ->
    @listViewHandler.select(data)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=> @editForm.editRecord(@listView.selectedRecord()))
  deselect: -> @noRowSelected()
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

  noRowSelected: ->
    @commandBar.disableCommands('edit', 'delete', 'upload')
  rowSelected: ->
    switch @selectedContentType
      when 'email'
        @commandBar.enableCommands('edit', 'delete')
      when 'page'
        @commandBar.enableCommand('edit')
      when 'terms'
        @commandBar.enableCommand('edit')
      when 'news'
        @commandBar.enableCommands('edit', 'delete', 'upload')
  contentTypeSelected: (type) ->
    @selectedContentType = type
    @noRowSelected()
    switch type
      when 'email'
        @commandBar.enableCommands('new')
        @commandBar.disableCommands('new', 'delete', 'upload')
      when 'page'
        @commandBar.disableCommands('new', 'delete', 'upload')
      when 'terms'
        @commandBar.enableCommand('new')
        @commandBar.disableCommands('delete', 'upload')
      when 'news'
        @commandBar.enableCommand('new')

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
      @newForm.newRecord()

      content_key = @newForm.node('content[key]')
      content_status = @newForm.node('content[status]')
      if @selectedContentType == 'terms'
        content_key.value = 'Terms'
        content_key.readOnly = true
      else
        content_key.readOnly = false

      if @selectedContentType == 'terms' || @selectedContentType == 'page'
        replaceOptions($(content_status), [{text: 'Published', value: 'PUBLISHED'}])
        content_status.value = 'PUBLISHED'
      else
        replaceOptions($(content_status), [{text: 'Draft', value: 'DRAFT'}, {text: 'Published', value: 'PUBLISHED'}])
        content_status.value = 'DRAFT'
      unless @selectedContentType == 'news'
        @viewport.find('.title-row').hide()
        @viewport.find('.thumbnail-row').hide())

  editSelectedRecord: ->
    if record = @listView.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editForm.editRecord(record))

  deleteRecord: ->
    if record = @listView.selectedRecord()
      ServerProxy.saveChanges("/office/delete_content/"+record.id, {}, NullActor, @db)

  revert: ->
    if @newForm.in()
      @newForm.revert()
    else if @editForm.in()
      @editForm.revert()

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

  filter: (data) ->
    @listView.setPage(1)
    @listView.setOffset(0)
    @listViewHandler.filter(data)
    @contentTypeSelected(data.filters.type)

    # Fill in hidden field which is used to pass content type through when storing new content
    @newForm.node('content[type]')?.value = data.filters.type

    # Content item name can't be edited for Terms and Page items
    @editForm.node('content[key]')?.readOnly = (data.filters.type == 'page' || data.filters.type == 'terms')
    @newForm.node('content[key]')?.readOnly = (data.filters.type == 'terms')

    # Name of Terms items are always 'Terms'
    if data.filters.type == 'terms'
      @newForm.node('content[key]')?.value = 'Terms'

  tryToSave: (callback) ->
    actor = Actor(
      saved: (data) ->
        callback()
        NotificationPopup.requestSuccess(data)
      failed: (data) ->
        NotificationPopup.requestError(data))

    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_content/', @db, actor, 'content')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_content', @db, actor, 'content')
    else
      callback()

  uploadThumbnail: ->
    @viewport.find('.popover form').fileupload({
      url: '/office/upload_content_thumbnail/' + @listView.selectedRecord().id,
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

window.ContentView = ContentView