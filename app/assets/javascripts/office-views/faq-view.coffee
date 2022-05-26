class FaqView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'FAQ'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)

    columns = [
      {name: 'Section',  id: 'topic'},
      {name: 'Question', id: 'question'},
      {name: 'Answer',   id: 'answer'},
      {name: 'Position', id: 'position', type: 'number'}]
    @listView = new ListView(@db, @viewport, 'faq_entries', columns, @)
    @listView.rowBuilder((record) ->
      answer = $(record.answer).text() #Strip out HTML tags for preview
      [record.topic,
       if record.question.length > 60 then (record.question.slice(0, 60) + '...') else record.question,
       if answer.length > 60 then (answer.slice(0, 60) + '...') else answer,
       record.position])
    @listViewHandler = new DefaultListViewHandler(@listView)

    fillInEditForm = (form, record) ->
      form.node('faq_entry[topic]').value = record.topic
      form.node('faq_entry[position]').value = record.position
      form.node('faq_entry[question]').value = record.question
      form.node('faq_entry[answer]').value = record.answer

    @editForm = new TinyMceForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    @newForm = new TinyMceForm(@viewport.find('.record-new'), @)
    @newForm = new SlidingForm(@newForm)

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

    @db.onUpdate('faq_entries', => @redraw())

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
  deselect: ->
    @commandBar.disableCommands('edit', 'delete')
  activate: (data) ->
    @listViewHandler.activate(data)
    @rowSelected()
    if @editForm.in()
      @tryToSave(=> @editForm.stopEditing())
    else if record = @listView.selectedRecord()
      @editForm.editRecord(record)

  rowSelected: ->
    @commandBar.enableCommands('edit', 'delete')

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
      ServerProxy.saveChanges("/office/delete_faq_entry/"+record.id, {}, NullActor, @db)

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

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_faq_entry/', @db, actor, 'faq_entry')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_faq_entry', @db, actor, 'faq_entry')
    else
      callback()

window.FaqView = FaqView