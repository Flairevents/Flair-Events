class TodoView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)
    @resetTodos()

    @db.onUpdate('todos', => @redraw())

    @viewport.find('.refresh-data').click(=>
      @db.refreshData())

  draw: ->
    if @todoMagicId == null || !@db.findId('todos', @todoMagicId)?
      @resetTodos()
    @populateTotal()

  filter: ->
    @resetTodos()
    @populateTotal()

  getTodos: ->
    @todos = @db.queryAll('todos', @filterBar.selectedFilters())

  showTodo: ->
    if @todos? && @todos.length > 0
      @displayTodo(@todos[0])
    else
      @clearTodo()

  resetTodos: ->
    @getTodos()
    @showTodo()

  skipTodo: ->
    if @todos?
      @todos.shift() # get rid of the first one
      if @todos.length > 0
        @displayTodo(@todos[0])
      else
        @getTodos() # go back to the beginning
        @showTodo()
    else
      @clearTodo()

  displayTodo: (todo) ->
    @todoMagicId = todo.magicid

    @viewport.find('a.zoomimg').jqZoomItDispose() # currently displayed to-do might contain a zoomed image
    @viewport.find('.todo-description').html(@buildTodoHtml(todo))
    @viewport.find('a.zoomimg').jqZoomIt()

    switch todo.type
      when 'id_approval'
        @viewport.find('.prospect-profile').hide()
        @flagExpiredVisa(@viewport.find("#visaexpiry#{todo.data.prospect_id}"), @db.findId('prospects', todo.data.prospect_id))
      when 'change'
        @fillProspectProfile(@db.findId('prospects', todo.prospect_id))
        @flagExpiredVisa(@viewport.find('.prospect-profile .prospect_visa_expiry'), @db.findId('prospects', todo.prospect_id))
      when 'share_code'
        @viewport.find('.prospect-profile').hide()
        @flagExpiredVisa(@viewport.find("#visaexpiry#{todo.data.prospect_id}"), @db.findId('prospects', todo.data.prospect_id))

    choiceArea = @viewport.find('.choices')
    choiceArea.empty()
    for choice in todo.choices
      do (choice) =>
        button = $('<button class="btn btn-default">' + choice.label + '</button>')
        choiceArea.append(button)
        button.click(=> @choiceClicked(choice))
    button = $('<button class="btn btn-default">Skip</button>')
    choiceArea.append(button)
    button.click(=> @skipTodo())

    choiceAreaTopRow = @viewport.find('.choices-top-row')
    choiceAreaTopRow.empty()
    for choice in todo.choices
      do (choice) =>
        button = $('<button class="btn btn-default">' + choice.label + '</button>')
        choiceAreaTopRow.append(button)
        button.click(=> @choiceClicked(choice))
    button = $('<button class="btn btn-default">Skip</button>')
    choiceAreaTopRow.append(button)
    button.click(=> @skipTodo())

  clearTodo: ->
    @todoMagicId = null
    @viewport.find('a.zoomimg').jqZoomItDispose() # maybe a zoomed image might have been displayed before...
    @viewport.find('.todo-description').text('Hurrah! You are all done.')
    @viewport.find('.prospect-profile').hide()
    @viewport.find('.choices').empty()
    @viewport.find('.choices-top-row').empty()

  showAllTodos: ->
    @viewport.find('#filter-type').val('')
    @filterBar.refreshWidths()
    @filter()
  showChangeRequests: ->
    @viewport.find('#filter-type').val('change')
    @filterBar.refreshWidths()
    @filter()
  showIdApprovalRequests: ->
    @viewport.find('#filter-type').val('id_approval')
    @filterBar.refreshWidths()
    @filter()
  showShareCodeRequests: ->
    @viewport.find('#filter-type').val('share_code')
    @filterBar.refreshWidths()
    @filter()

  fillProspectProfile: (prospect) ->
    form = @viewport.find('.prospect-profile').show()
    form.find('.prospect_id').text(prospect.id)
    form.find('.prospect_date_start').text(printDate(prospect.date_start))
    form.find('.prospect_first_name').text(prospect.first_name)
    form.find('.prospect_last_name').text(prospect.last_name)
    form.find('.prospect_date_of_birth').text(printDate(prospect.date_of_birth))
    form.find('.prospect_gender').text(prospect.gender || 'Unknown')
    form.find('.prospect_address').text(prospect.address || '')
    form.find('.prospect_address2').text(prospect.address2 || '')
    form.find('.prospect_city').text(prospect.city || '')
    form.find('.prospect_post_code').text(prospect.post_code || '')
    form.find('.prospect_email').text(prospect.email || '')
    form.find('.prospect_mobile_no').text(prospect.mobile_no || '')
    form.find('.prospect_home_no').text(prospect.home_no || '')
    form.find('.prospect_emergency_no').text(prospect.emergency_no || '')
    form.find('.prospect_emergency_name').text(prospect.emergency_name || '')
    form.find('.prospect_city_of_study').text(prospect.city_of_study || '')
    form.find('.prospect_tax_choice').text(prospect.tax_choice || '')
    form.find('.prospect_student_loan').text(if prospect.student_loan then 'Yes' else 'No')
    form.find('.prospect_bank_account_name').text(prospect.bank_account_name || '')
    form.find('.prospect_bank_sort_code').text(prospect.bank_sort_code || '')
    form.find('.prospect_bar_experience').text(prospect.bar_experience || 'None')
    form.find('.prospect_bar_license_type').text(prospect.bar_license_type || '')
    form.find('.prospect_bar_license_no').text(prospect.bar_license_no || '')
    form.find('.prospect_bar_license_expiry').text(prospect.bar_license_expiry && printDate(prospect.bar_license_expiry) || '')
    form.find('.prospect_training_type').text(prospect.training_type || '')
    form.find('.prospect_agreed_terms').text(if prospect.agreed_terms then 'Yes' else 'No')
    form.find('.prospect_id_type option').text(prospect.id_type || '')
    form.find('.prospect_visa_number').text(prospect.visa_number || '')
    form.find('.prospect_visa_expiry').text(printDate(prospect.visa_expiry))
    form.find('.prospect_id_approved').text(if prospect.id_sighted? then 'Yes' else 'No')
    form.find('.prospect_nationality').text(window.Countries[prospect.nationality_id] || '')
    form.find('.prospect_notes').text(prospect.notes || '')
    form.find('.prospect_photo').attr('src', '/prospect_photo/'+prospect.id)

    form.find('.prospect_bank_account_no').text(prospect.bank_account_no || '')
    form.find('.prospect_id_number').text(prospect.id_number || '')
    form.find('.prospect_ni_number').text(prospect.ni_number || '')

    form.find('.prospect_good_sport').text(if prospect.good_sport then 'Yes' else 'No')
    form.find('.prospect_good_bar').text(if prospect.good_bar then 'Yes' else 'No')
    form.find('.prospect_good_promo').text(if prospect.good_promo then 'Yes' else 'No')
    form.find('.prospect_good_hospitality').text(if prospect.good_hospitality then 'Yes' else 'No')
    form.find('.prospect_good_management').text(if prospect.good_management then 'Yes' else 'No')
    form.find('.prospect_status').text(prospect.status)

  choiceClicked: (choice) ->
    id = @db.findId('todos', @todoMagicId).id
    if choice.needs_reason
      fnReject = (params) =>
        ServerProxy.sendRequest(choice.url, $.extend({id: id}, params), Actor(
          requestSuccess: =>
            @shiftTodos())
          , @db)
      showReasonDialog('Reject', fnReject, {id_messages: true, skip_log: true})
    else
      ServerProxy.saveChanges(choice.url + id, {}, Actor(
        requestSuccess: =>
          @shiftTodos())
        , @db)

  shiftTodos: ->
    @todos.shift() # get rid of one just completed
    if @todos.length > 0
      @displayTodo(@todos[0])
    else
      @getTodos() # go back to the beginning
      if @todos.length > 0
        @showTodo()
      else
        @clearTodo()

  populateTotal: ->
    if @db.tables.todos?
      typeFilter = @viewport.find('#filter-type').val()
      if typeFilter == ''
        @viewport.find('.remaining-todo-count').text("#{Object.keys(@db.tables.todos).length}")
      else
        filtered_todos = Object.entries(@db.tables.todos).filter (todo) -> todo[1].type == typeFilter
        @viewport.find('.remaining-todo-count').text("#{filtered_todos.length}")
    else
      @viewport.find('.remaining-todo-count').text('0')

  buildTodoHtml: (todo) ->
    switch todo.type
      when 'change'
        '<b>' + escapeHTML(todo.data.content).replace(/\n/g, '<br>') + '</b>'
      when 'id_approval'
        JST['office_views/_id_approval'](todo.data)
      when 'share_code'
        JST['office_views/_share_code_approval'](todo.data)

  flagExpiredVisa: (visa_expiry, prospect) ->
    today = getToday()
    if prospect.visa_expiry && prospect.visa_expiry < getToday()
      visa_expiry.addClass('visa_expired')
    else
      visa_expiry.removeClass('visa_expired')

window.TodoView = TodoView
