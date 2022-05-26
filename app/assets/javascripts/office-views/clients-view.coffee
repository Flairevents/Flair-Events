class ClientsView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Clients'

    clientColumns = [
      {id: 'name',              name: 'Name'},
      {id: 'terms_status',      name: 'T&C'}
      {id: 'safety_status',     name: 'H&S'}
      {id: 'contact',           name: 'Primary Contact', changes_with: 'primary_client_contact_id', virtual: true}
      {id: 'contact_mobile_no', name: 'Contact Phone',   changes_with: 'primary_client_contact_id', virtual: true}
      {id: 'contact_email',     name: 'Contact Email',   changes_with: 'primary_client_contact_id', virtual: true}
      {id: 'flair_contact',     name: 'Flair Contact'}
      {id: 'phone_no',          name: 'Company Phone'}
      {id: 'email',             name: 'Company Email'}
    ]

    clientFormBuilder = (client) =>
      contact = @db.findId('client_contacts', client.primary_client_contact_id)
      [ client.name,
        client.terms_status,
        client.safety_status,
        if contact then "#{contact.first_name} #{contact.last_name}" else '',
        if contact then contact.mobile_no else '',
        if contact then contact.email else '',
        client.flair_contact,
        client.phone_no,
        client.email,
      ]

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('.filter-bar'), @)

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'clients', clientColumns, clientFormBuilder, Actor(
      select: (data) => @select(data)
      deselect: => @commandBar.disableCommands('edit', 'delete')
      activate: (data) => @activate(data)
      clean: => @clean()
      dirty: => @dirty()))

    @table.sortOnColumn('name', true)
    @table.setFilters(@filterBar.selectedFilters())

    autosize(@viewport.find('.record-edit textarea'))
    autosize(@viewport.find('.record-new textarea'))
    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, @fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    @newForm  = new RecordEditForm(@viewport.find('.record-new'), @)
    @newForm  = new SlidingForm(@newForm)

    eventClientColumns = [
      {name: 'Name',  id: 'event_name'},
      {name: 'Status', id: 'event_status'},
      {name: 'Start', id: 'event_date_start', type: 'date'},
      {name: 'End',   id: 'event_date_end', type: 'date'}
    ]

    @eventsList = new ListView(@db, @viewport.find('#client-events'), 'event_clients', eventClientColumns)
    @eventsList.sortOnColumn('event_date_start', false)

    futureEventClientColumns = [
      {name: 'Needs Booking?', id: 'event_requires_booking'}
      {name: 'Name',  id: 'event_name'},
      {name: 'Status', id: 'event_status'},
      {name: 'Start', id: 'event_date_start', type: 'date'},
      {name: 'End',   id: 'event_date_end', type: 'date'}
    ]
    futureEventRowBuilder = (event_client) =>
      event = @db.findId('events', event_client.event_id)
      ["<input type='hidden' value='0' name='[events][#{event.id}][requires_booking]'><input type='checkbox' class='event-requires-booking' value = '1' name='[events][#{event.id}][requires_booking]'" + (if event.requires_booking then " checked='checked'" else "") + ">",
        escapeHTML(event.name),
        event.status,
        printDate(event.date_start),
        printDate(event.date_end)]

    @futureEventsList = new EditableStaticListView(@db, @viewport.find('#client-future-events'), 'event_clients', futureEventClientColumns, futureEventRowBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_events', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)))
    @futureEventsList.sortOnColumn('event_date_start', true)

    @reportDownloader = new ReportDownloader(@table)
    @reportDialog = new ReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new ReportMenu(@viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    clientContactColumns = [
      {name: 'Client ID', id: 'client_id', hidden: true}
      {name: 'First Name', id: 'first_name'},
      {name: 'Last Name', id: 'last_name'},
      {name: 'Email', id: 'email'},
      {name: 'Mobile', id: 'mobile_no'},
      {name: 'Account Status', id: 'account_status'},
      {name: 'Delete', sortable: false}]
    clientContactBuilder = (client_contact) =>
      client_id = client_contact.client_id || @editForm.editingId()
      if client_contact.id < 0
        delete_link = ''
      else
        delete_link = $("<a style='color:red' href='javascript:void(0)'>X</a>")
        delete_link.click(=> ServerProxy.sendRequest("/office/delete_client_contact/" + client_contact.id, {}, ErrorOnlyPopup, @db) if client_contact.id != -1)
      [ buildHiddenInput('client_id', client_id),
        buildTextInput({name: "[client_contacts][#{client_contact.id}][first_name]", value: client_contact.first_name, otherHtml: "id='client_contact_#{client_contact.id}_first_name'"}),
        buildTextInput({name: "[client_contacts][#{client_contact.id}][last_name]",  value: client_contact.last_name,  otherHtml: "id='client_contact_#{client_contact.id}_last_name'"}),
        buildTextInput({name: "[client_contacts][#{client_contact.id}][email]",      value: client_contact.email,      otherHtml: "id='client_contact_#{client_contact.id}_email'"}),
        buildTextInput({name: "[client_contacts][#{client_contact.id}][mobile_no]",  value: client_contact.mobile_no,  otherHtml: "id='client_contact_#{client_contact.id}_mobile_no'"}),
        [@clientContactStatusToHtml(client_contact.account_status), (($td) => $td.find('.send-invitation').click(=> ServerProxy.saveChanges("/office/invite_client_contact", {id: client_contact.id})))],
        buildDeleteLink(client_contact.id, 'delete_client_contact')]

    @clientContactsTable = new EditableListView(@db, @viewport.find('#client-contacts'), 'client_contacts', clientContactColumns, clientContactBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_client_contacts', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      clean: => @clean()
      dirty: => @dirty()))
    @clientContactsTable.displayBlankRow({id: -1, first_name: '', last_name: '', email: '', mobile_no: ''})
    @clientContactsTable.sortOnColumn('first_name', true)

    @displayedTab = 'client-details'
    @viewport.find('.record-edit .slideover-tabs a').click((event) =>
      event.preventDefault()
      link   = $(event.target)
      newTab = link.attr('href').slice(1)
      if newTab != @displayedTab
        @tryToSave(=>
          @displayedTab = newTab
          link.tab('show')
          @refreshForm()))

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
    @db.onUpdate('events', =>
      if @editForm.in()
        @drawEventLists())
    @db.onUpdate('client_contacts', =>
      if @editForm.in()
        @clientContactsTable.draw())
    @db.onUpdate(['clients', 'client_contacts'], => @redraw())

  clientContactStatusToHtml: (status) ->
    switch status
      when 'NEW' then "<a class='send-invitation' href='javascript:void(0)'>Send Invitation</a>"
      when 'INVITED' then "Invited (<a class='send-invitation' href='javascript:void(0)'>Resend Invitation</a>)"
      when 'CONFIRMED_EMAIL' then "Confirmed Email (<a class='send-invitation' href='javascript:void(0)'>Resend Invitation</a>)"
      when 'ACTIVATED' then "Activated"
      else status

  draw: ->
    @table.draw()
    rebind(@viewport.find('.record-list select').not('.never-dirty'), 'change', @saveCurrentRow)

  saveCurrentRow: =>
    @table.saveCurrentRow()

  newRecord: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#client-details"]').tab('show')
      @newForm.newRecord())

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        @editRecord(record))

  editRecord: (record) ->
    @clientContactsTable.filter({filters: {client_id: record.id}})
    @clientContactsTable.deselectRow()
    @clientContactsTable.draw()
    @viewport.find('input[name="client_id"]').val(record.id)
    @viewport.find('.client-events-tab').text('Events (' + record.event_ids.length + ')')
    @viewport.find('.client-future-events-tab').text('Future Events (' + record.future_event_ids.length + ')')
    @eventsList.filter(filters: {client_id: record.id, started_only: true})
    @futureEventsList.filter(filters: {client_id: record.id, future_only: true})
    @drawEventLists()
    @editForm.editRecord(record)

  revert: ->
    if @editForm.in()
      @editForm.revert()
    else if @newForm.in()
      @newForm.revert()

  clearFilters: ->
    @filterBar.clearFilters()
    @filter({filters: @filterBar.selectedFilters()})

  filter: (data) ->
    @table.setPage(1)
    @table.setOffset(0)
    @table.deselectRow()
    @table.setFilters(data.filters)
    @table.draw()

  select: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=> @editRecord(data.record))

  activate: (data) ->
    @rowSelected(data)
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#client-details"]').tab('show'))
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editRecord(data.record))
    else
      @editRecord(data.record)

  postSlideIn: ->
    if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))
    else if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))

  saveAll: ->
    if @newForm.in()
      @tryToSave(=>
        if record = @db.queryAll('clients', {name: @newForm.node('client[name]').value})[0]
          @newForm.stopEditing()
          @editRecord(record))
    else
      @tryToSave(=>
        @refreshForm())

  refreshForm: ->
    @editForm.refreshForm(@db, 'clients')

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @viewport.find('.record-edit a[href="#client-details"]').tab('show')
      else if @newForm.in()
        @newForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
      @viewport.find('.record-edit a[href="#client-details"]').tab('show')
    else if @newForm.in()
      @newForm.stopEditing()

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  tryToSave: (callback) ->
    actor = Actor({saved: callback})

    if @editForm.in() && @editForm.isDirty()
      @clientContactsTable.save(actor)
      @editForm.saveRecord('/office/update_client/', @db, actor, 'client')
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_client', @db, actor, 'client')
    else
      callback()

  dirty: ->
    @commandBar.enableCommand('revert')
  clean: ->
    @commandBar.disableCommand('revert')

  rowSelected: (data) ->
    @commandBar.enableCommands('edit', 'delete')

  drawEventLists: =>
    @eventsList.draw()
    @futureEventsList.draw()
    rebind(@viewport.find('.event-requires-booking'), 'change', @requiresBookingCheckboxHandler)

  requiresBookingCheckboxHandler: =>
    @futureEventsList.saveCurrentRow()

  fillInEditForm: (form, record) =>
    form.find('select option:selected').removeAttr('selected')
    fillInput(form.node('client[active]'), record.active)
    fillInput(form.node('client[name]'), record.name)
    fillInput(form.node('client[company_type]'), record.company_type)
    fillInput(form.node('client[address]'), record.address)
    fillInput(form.node('client[phone_no]'), record.phone_no)
    fillInput(form.node('client[email]'), record.email)
    fillInput(form.node('client[accountant_email]'), record.accountant_email)
    fillInput(form.node('client[flair_contact]'), record.flair_contact)
    fillDateInput($(form.node('client[terms_date_sent]')), record.terms_date_sent)
    fillDateInput($(form.node('client[terms_date_received]')), record.terms_date_received)
    fillDateInput($(form.node('client[safety_date_sent]')), record.safety_date_sent)
    fillDateInput($(form.node('client[safety_date_received]')), record.safety_date_received)
    fillInput(form.node('client[notes]'), record.notes)
    fillInput(form.node('client[invoice_notes]'), record.invoice_notes)
    options = []
    options.push(['',''])
    for client_contact in @db.queryAll('client_contacts', {client_id: record.id})
      options.push(["#{client_contact.first_name} #{client_contact.last_name}", client_contact.id])
    options = options.sort (o1, o2) ->
      if o1[0] > o2[0] then 1 else if o1[0] < o2[0] then -1 else 0
    @editForm.node('client[primary_client_contact_id]').innerHTML = buildOptions(options, record.primary_client_contact_id)
    @editForm.node('client[terms_client_contact_id]'  ).innerHTML = buildOptions(options, record.terms_client_contact_id)
    @editForm.node('client[safety_client_contact_id]' ).innerHTML = buildOptions(options, record.safety_client_contact_id)

  deleteRecord: ->
    ServerProxy.sendRequest('/office/delete_client/' + @table.selectedRecord().id, {}, ErrorOnlyPopup, @db)

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

window.ClientsView = ClientsView
