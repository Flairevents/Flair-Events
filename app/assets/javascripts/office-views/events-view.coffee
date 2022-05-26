class EventsView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Events'
    @columns = [
      {id:"admin_completed", name: "Admin?"}
      {id:"name",            name: "Name", changes_with: ['admin_completed', 'name']},
      {id:"staff_needed",    name: "Need", type:"number"},
      {id:"n_active_gigs",   name: "Hired", type:"number"},
      {id:"n_gig_requests",  name: "Rqst", type:"number"},
      {id:"n_gig_requests_spare",  name: "Sp", type:"number"},
      {id:"show_in_public",  name: "Web"},
      {id:"fullness",        name: "Levels"},
      {id:"office_manager_id",                      name: "Staff HQ"},
      {id:"senior_manager_id",          name: "Senior HQ"}
      {id:"n_incomplete_tasks",                     name: "Tasks"},
      {id:"site_manager",    name: "Site Rep"},
      {id:"date_start",      name: "Start Date",  type:"date"},
      {id:"duration",        name: "Days",   type:"number"}
      {id:"region_name",     name: "Region", virtual:true, sort_by: (evt) -> regionForRecord(evt) },
      {id:"location",        name: "Location"},
      {id:"accom_status",    name: "Acc"},
      {id:"booking_status",  name: "Book"}
      {id:"client_names",    name: "Client"},
      {id:"category_name",   name: "Category", virtual:true, sort_by: (evt) -> window.EventCategories[evt.category_id] },
      {id:"status",          name: "Status"}]

    eventListBuilder = (event) =>
      ["<input type='hidden' value='0' name='[events][#{event.id}][admin_completed]'><input type='checkbox' class='event-admin-completed' value = '1' name='[events][#{event.id}][admin_completed]'" + (if event.admin_completed then " checked='checked'" else "") + ">",
        (if event.admin_completed then "<span class='hilite event-name'>#{event.name}</span>" else "<span class='event-name'>#{event.name}</span>"),
        if event.additional_staff > 0
          (event.staff_needed || '') + " (+#{event.additional_staff})"
        else
          event.staff_needed
        ,
        if event.n_active_gigs == 0
          ''
        else
          if event.n_active_gigs < event.staff_needed
            "<a class='red-text--bold' href='javascript:void(0)' onclick=\"viewManager.send('gigs', 'showHiredForEvent', {event_id: #{event.id}})\">" + event.n_active_gigs + '</a>'
          else
            "<a href='javascript:void(0)' onclick=\"viewManager.send('gigs', 'showHiredForEvent', {event_id: #{event.id}})\">" + event.n_active_gigs + '</a>'
        ,
        if event.n_gig_requests == 0 then '' else "<a href='javascript:void(0)' onclick=\"viewManager.send('gigs', 'showRequestsForEvent', {event_id: #{event.id}, spare: 'false', ignored: 'false'})\">" + event.n_gig_requests + '</a>',
        if event.n_gig_requests_spare == 0 then '' else "<a href='javascript:void(0)' onclick=\"viewManager.send('gigs', 'showRequestsForEvent', {event_id: #{event.id}, spare: 'true'})\">" + event.n_gig_requests_spare + '</a>',
        if event.show_in_public then '✓' else '',
        if event.fullness == 'REGISTER_INTEREST' then 'INTEREST' else event.fullness,

        @db.findId('officers', event.office_manager_id)?.first_name || '',
        @db.findId('officers', event.senior_manager_id)?.first_name || '',
        if event.show_in_planner && event.n_incomplete_tasks > 0 then "<a href='javascript:void(0)' onclick=\"viewManager.send('planner', 'showTasksForEvent', {event_id: #{event.id}})\">" + event.n_incomplete_tasks + '</a>' else 0,
        event.site_manager,
        moment(event.date_start).format('DD-MM-YY'),
        event.duration,
        regionForRecord(event),
        event.location,

        switch event.accom_status
          when 'NONE' then ''
          when 'NEED' then 'Y'
          when 'BOOKED' then 'Bkd'
          when 'CANCELLED' then 'Cx'
          when 'REFUND' then 'Ref'
        ,
        event.booking_status,
        event.client_names,

        window.EventCategories[event.category_id],
        sentenceCase(event.status)
      ]

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar = new FilterBar(@viewport.find('#events-filter-bar'), @)

    @shiftsFilterBar = new FilterBar(@viewport.find('#shifts-filter-bar'), Actor({
        beforeFilter: =>
          @updateShiftDateDropdown()
        filter: (data) =>
          data.filters['event_id'] = @eventId
          data.filters['date'] = new Date(Date.parse(data.filters.date)) if data.filters.date
          @shiftsTable.setFilters(data.filters)
          @shiftsTable.draw()
          @shiftsTable.refreshBlanks()
      }))

    @assignmentsFilterBar = new FilterBar(@viewport.find('#assignments-filter-bar'), Actor({
        beforeFilter: =>
          @updateAssignmentDateDropdown()
          @updateShiftDropdowns()
        filter: (data) =>
          data.filters['event_id'] = @eventId
          data.filters['date'] = new Date(Date.parse(data.filters.date)) if data.filters.date
          @assignmentsTable.setFilters(data.filters)
          totalStaffNeeded = 0
          for record in @assignmentsTable.allRecords()
            totalStaffNeeded += record.staff_needed
          @viewport.find('#assignments-total-needed').html(totalStaffNeeded)
          @assignmentsTable.draw()
          @assignmentsTable.refreshBlanks()
      }))

    @table = new EditableStaticListView(@db, @viewport.find('.list-view'), 'events', @columns, eventListBuilder, Actor(
      save: (data) => @saveChanges('/office/update_events', data.data, data.actor)
      select: (data) => @select(data)
      deselect: => @commandBar.disableCommands('edit', 'duplicate', 'delete', 'upload')
      activate: (data) => @activate(data)
      clean: => @clean()
      dirty: => @dirty()))

    @table.pageSize(18)
    @table.sortOnColumn('date_start', true)

    @map = new MapView(@viewport.find('.map-view'), @)
    @map = new QueryMap(@map, @db, 'events')

    @shownSubview = 'table'

    autosize(@viewport.find('.record-edit textarea'))
    autosize(@viewport.find('.record-new textarea'))
    autosize(@viewport.find('.record-new-booking textarea'))

    fillInEditForm = ($form, record) =>
      # fill up jobs select
      jobs = @db.queryAll('jobs', {event_id: record.id})
      first_job = null
      $($form.node('job[new_description]')).prop('disabled', true)
      $($form.node('job[uniform_information]')).prop('disabled', true)
      $($form.node('job[description]')).prop('disabled', true)
      $($form.node('job[shift_information]')).prop('disabled', true)

      $($form.node('job[new_description]')).val('')
      $($form.node('job[description]')).val('')
      $($form.node('job[uniform_information]')).val('')
      $($form.node('job[shift_information]')).val('')
      if jobs != undefined
        # if $($form.node('job[id]')).children().length == 0
        options = ""
        first_job = jobs[0]

        if first_job != undefined
          $($form.node('job[new_description]')).val(first_job.new_description)
          $($form.node('job[uniform_information]')).val(first_job.uniform_information)
          $($form.node('job[description]')).val(first_job.description)
          $($form.node('job[shift_information]')).val(first_job.shift_information)

          $($form.node('job[new_description]')).prop('disabled', false)
          $($form.node('job[uniform_information]')).prop('disabled', false)
          $($form.node('job[shift_information]')).prop('disabled', false)

        for job in jobs
          options += "<option value='" + job.id + "'>" + job.name + "</option>"
        $($form.node('job[id]')).html(options)
        # for job in jobs
        #   $($form.node('job[id]')).append("<option value='" + job.id + "'>" + job.name + "</option>")
      else
        $($form.node('job[new_description]')).prop('disabled', true)
        $($form.node('job[uniform_information]')).prop('disabled', true)
        $($form.node('job[description]')).prop('disabled', false)
        $($form.node('job[shift_information]')).prop('disabled', true)

        $($form.node('job[new_description]')).val('')
        $($form.node('job[uniform_information]')).val('')
        $($form.node('job[description]')).val('')
        $($form.node('job[shift_information]')).val('')

      fillInput($form.node('event[request_message]'), record.request_message)
      fillInput($form.node('event[spares_message]'), record.spares_message)
      fillInput($form.node('event[applicants_message]'), record.applicants_message)
      fillInput($form.node('event[action_message]'), record.action_message)
      fillInput($form.node('event[name]'), record.name)
      fillInput($form.node('event[display_name]'), record.display_name)
      fillInput($form.node('event[other_info]'), record.other_info)
      if record.blurb_legacy?
        $form.find('.structured-blurb').hide()
        fillInput($form.node('event[blurb_legacy]'), record.blurb_legacy)
        $form.find('.legacy-blurb').show()
      else
        $form.find('.legacy-blurb').hide()
        fillInput($form.node('event[blurb_title]'), record.blurb_title)
        fillInput($form.node('event[blurb_subtitle]'), record.blurb_subtitle)
        fillInput($form.node('event[blurb_opening]'), record.blurb_opening)
        fillInput($form.node('event[blurb_job]'), record.blurb_job)
        fillInput($form.node('event[blurb_shift]'), record.blurb_shift)
        fillInput($form.node('event[blurb_wage_additional]'), record.blurb_wage_additional)
        fillInput($form.node('event[blurb_uniform]'), record.blurb_uniform)
        fillInput($form.node('event[blurb_transport]'), record.blurb_transport)
        fillInput($form.node('event[blurb_closing]'), record.blurb_closing)
        $form.find('.structured-blurb').show()
      fillInput($form.node('event[notes]'), record.notes)
      fillInput($form.node('event[location]'), record.location)
      fillInput($form.node('event[address]'), record.address)
      fillInput($form.node('event[post_code]'), record.post_code)
      fillInput($form.node('event[website]'), record.website)
      fillDateInput($($form.node('event[date_start]')), record.date_start)
      fillDateInput($($form.node('event[date_end]')), record.date_end)
      fillDateInput($($form.node('event[public_date_start]')), record.public_date_start)
      fillDateInput($($form.node('event[public_date_end]')), record.public_date_end)
      fillDateInput($($form.node('event[date_callback_due]')), record.date_callback_due)
      fillInput($form.node('event[category_id]'), record.category_id)
      fillInput($form.node('event[size_id]'), record.size_id)
      $form.find('.event_photo').attr('src', if record.photo? then '/event_photos/'+record.photo+'?force_refresh='+Math.random() else '')
      fillInput($form.node('event[staff_needed]'), record.staff_needed)
      fillInput($form.node('event[additional_staff]'), record.additional_staff)
      if record.additional_staff > 0 && record.gigs_count > 0
        $form.find('#edit_event_gigs_count').text("#{record.gigs_count} (#{record.gigs_count + record.additional_staff} Total)")
      else
        $form.find('#edit_event_gigs_count').text(record.gigs_count)
      fillInput($form.node('event[fullness]'), record.fullness)
      fillInput($form.node('event[paid_breaks]'), record.paid_breaks)
      fillInput($form.node('event[requires_booking]'), record.requires_booking)
      fillInput($form.node('event[remove_task]'), record.id)
      fillInput($form.node('event[send_scheduled_to_work_auto_email]'), record.send_scheduled_to_work_auto_email)
      fillInput($form.node('event[show_in_home]'), record.show_in_home)
      fillInput($form.node('event[show_in_planner]'), record.show_in_planner)
      fillInput($form.node('event[show_in_payroll]'), record.show_in_payroll)
      fillInput($form.node('event[show_in_public]'), record.show_in_public)
      fillInput($form.node('event[show_in_history]'), record.show_in_history)
      fillInput($form.node('event[is_restricted]'), record.is_restricted)
      fillInput($form.node('event[show_in_time_clocking_app]'), record.show_in_time_clocking_app)
      fillInput($form.node('event[show_in_ongoing]'), record.show_in_ongoing)
      fillInput($form.node('event[show_in_featured]'), record.show_in_featured)
      fillInput($form.node('event[jobs_description]'), record.jobs_description)
      fillInput($form.node('event[site_manager]'), record.site_manager)
      fillInput($form.node('event[office_manager_id]'), record.office_manager_id)
      fillInput($form.node('event[senior_manager_id]'), record.senior_manager_id)
      @updateOfficerDropdowns('#edit_event .active-operational-managers-dropdown', [['','']], record.office_manager_id)
      @updateOfficerSeniorManagerDropdowns('#edit_event .active-senior-managers-dropdown', [['','']], record.senior_manager_id)
      @updateOfficerDropdowns('#edit_event .active-operational-review-managers-dropdown', [['','']], record.reviewed_by_manager)
      $($form.node('event[client]')).val(record.client)
      fillInput($form.node('event[require_training_ethics]'), record.require_training_ethics)
      fillInput($form.node('event[require_training_customer_service]'), record.require_training_customer_service)
      fillInput($form.node('event[require_training_sports]'), record.require_training_sports)
      fillInput($form.node('event[require_training_bar_hospitality]'), record.require_training_bar_hospitality)
      fillInput($form.node('event[require_training_health_safety]'), record.require_training_health_safety)

      fillInput($form.node('event[has_bar]'), record.has_bar)
      fillInput($form.node('event[has_festivals]'), record.has_festivals)
      fillInput($form.node('event[has_office]'), record.has_office)
      fillInput($form.node('event[has_promotional]'), record.has_promotional)
      fillInput($form.node('event[has_hospitality]'), record.has_hospitality)
      fillInput($form.node('event[has_warehouse]'), record.has_warehouse)
      fillInput($form.node('event[has_retail]'), record.has_retail)
      fillInput($form.node('event[has_sport]'), record.has_sport)

      # fill in 'status' dropdown with statuses which can validly be chosen for this Event
      choices =
        BOOKING: [['Booking','BOOKING'],['New','NEW']],
        NEW:  [['Booking','BOOKING'],['New','NEW'],['Open','OPEN'],['Cancelled','CANCELLED']],
        OPEN: [['New','NEW'],['Open','OPEN'],['Happening','HAPPENING'],['Cancelled','CANCELLED']],
        HAPPENING: [['Open','OPEN'],['Happening','HAPPENING'],['Finished','FINISHED'],['Cancelled','CANCELLED']],
        FINISHED: [['Open','OPEN'],['Happening','HAPPENING'],['Finished','FINISHED'],['Closed', 'CLOSED'],['Cancelled','CANCELLED']],
        CLOSED:  [['Open','OPEN'],['Happening','HAPPENING'],['Finished','FINISHED'],['Closed', 'CLOSED'],['Cancelled','CANCELLED']],
        CANCELLED: [['Open','OPEN'],['Cancelled','CANCELLED'],['Closed','CLOSED']]
      $($form.node('event[status]')).html(buildOptions(choices[record.status], record.status))

      @populateClientChoices($form, record.client_ids)
      @populateLeaderClientContactChoices($('#event-leaders'), record.client_ids, record.leader_client_contact_id)
      autosize.update($form.find('textarea'))

    fillInNewForm = ($form) =>
      @populateClientChoices($form, null)
      fillInput($form.node('event[additional_staff]'), 0)
      autosize.update($form.find('textarea'))

    fillInNewBookingForm = ($form) =>
      $form.find('.booking-message').text('').hide()
      @populateClientChoices($form, null)
      $form.node('client_contact[id]').innerHTML = ''
      $form.find('.command-bar').hide()
      $($form.node('booking[client_id]')).closest('tr').hide()
      $form.find('table.booking-fields').hide()
      autosize.update($form.find('textarea'))

    @editForm = new TinyMceForm(@viewport.find('.record-edit #event-details'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm, @viewport.find('.record-edit'))
    editFormRemoveTasks = @editForm

    @newForm  = new TinyMceForm(@viewport.find('.record-new'), @, fillInNewForm)
    @newForm  = new SlidingForm(@newForm)
    @viewport.find('.record-new select[name="event[status]"]').html(buildOptions([['New','NEW']]))

    fillInBookingForm = ($form, event) =>
      $bookingMessage = $form.find('.booking-message')
      if event.requires_booking
        $bookingMessage.text('').hide()
      else
        $bookingMessage.text('Booking Not Required').show()
      fillInput($form.node('event[name]'), event.name)
      fillInput($form.node('event[display_name]'), event.display_name)
      fillInput($form.node('event[address]'), event.address)
      fillDateInput($($form.node('event[date_start]')), event.date_start)
      fillDateInput($($form.node('event[date_end]')), event.date_end)
      #Other form fields are populated by 'select' dropdown callbacks
      @populateClientChoices($form, event.client_ids)
      $form.find(".email_event_display_name").text(event.display_name)
      $form.find(".email_event_address").text(event.address)
      autosize.update($form.find('textarea'))

    @bookingCommandBar = new CommandBar(@viewport.find('.record-edit #event-booking.command-bar'), @)
    @bookingForm = new RecordEditForm(@viewport.find('.record-edit #event-booking'), @, fillInBookingForm)

    @newBookingForm  = new TinyMceForm(@viewport.find('.record-new-booking'), @, fillInNewBookingForm)
    @newBookingForm  = new SlidingForm(@newBookingForm)
    @viewport.find('.record-new-booking select[name="event[status]"]').html(buildOptions([['Booking','BOOKING']]))
    @viewport.find('.booking-email-template').hide()

    @bindClientHandlers(@viewport.find('.record-new-booking'))
    @bindClientHandlers(@viewport.find('.record-edit #event-booking'))

    @viewport.find('.record-edit .booking-update-email-fields textarea, .record-edit .booking-update-email-fields select, .record-edit .booking-update-email-fields input').on('change', @updateEmailField)

    @viewport.find('.record-edit select[name="booking[health_safety_template]"]').on('change', (e) =>
      $bookingHealthSafety =  @viewport.find('.record-edit textarea[name="booking[health_safety]"]')
      $bookingHealthSafety.val(@getHealthSafetyString(e.target.value)).change()
      autosize.update($bookingHealthSafety)
    )

    leaderColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true},
      {name: 'Type', id: 'user_type'},
      {name: 'Name', id: 'user_id'},
      {name: 'Enabled', id: 'enabled'},
      {name: 'Del', sortable: false}]
    leaderRowBuilder = (leader) =>
      eventId = leader.event_id || @editForm.editingId()
      user_type = leader.user_type || ''
      user_id = leader.user_id || ''
      [ buildHiddenInput("event_id", eventId),
        [buildSelect({name: "[team_leader_roles][" + leader.id + "][user_type]", options:[['',''],['Employee','Prospect'],['Office Staff','Officer'],['Client', 'ClientContact']], selected: user_type}),
          ($td) =>
            index = $td.find('select').closest('tr').data('index')
            val = $td.find('select').on('change', =>
              $tr = @viewport.find('#event-leaders').find("tr[data-index='" + index + "']")
              $source = $tr.find("select[name='[team_leader_roles][" + leader.id + "][user_type]']")
              $target = $tr.find("select[name='[team_leader_roles][" + leader.id + "][user_id]']")
              @updateLeaderUserOptions($target, @eventId, $source.val()))
        ],
        buildSelect({name: "[team_leader_roles][" + leader.id + "][user_id]", options: @getLeaderOptions(eventId, user_type), selected: user_id}),
        "<input type='checkbox' name='[team_leader_roles][" + leader.id + "][enabled]'" + (if leader.enabled then " checked='checked'" else "") + ">",
        buildDeleteLink(leader.id, 'delete_team_leader_role')]
    @leadersTable = new EditableListView(@db, @viewport.find('#event-leaders'), 'team_leader_roles', leaderColumns, leaderRowBuilder,
      Actor(
        save: (data) =>
          @saveChanges('/office/update_team_leader_roles', data.data, data.actor)
        clean: => @clean()
        dirty: => @dirty()))
    @leadersTable.displayBlankRow({id: -1, user_type: '', user_id: '', enabled: true})
    @leadersTable.sortOnColumn('user_type', true)

    fillInLeadersForm = ($form, record) ->
      fillInput($form.node('event[leader_general]'), record.leader_general)
      fillInput($form.node('event[leader_flair_phone_no]'), record.leader_flair_phone_no)
      fillInput($form.node('event[leader_meeting_location]'), record.leader_meeting_location)
      fillInput($form.node('event[leader_meeting_location_coords]'), record.leader_meeting_location_coords)
      fillInput($form.node('event[leader_accomodation]'), record.leader_accomodation)
      fillInput($form.node('event[leader_job_role]'), record.leader_job_role)
      fillInput($form.node('event[leader_arrival_time]'), record.leader_arrival_time)
      fillInput($form.node('event[leader_handbooks]'), record.leader_handbooks)
      fillInput($form.node('event[leader_staff_job_roles]'), record.leader_staff_job_roles)
      fillInput($form.node('event[leader_staff_arrival]'), record.leader_staff_arrival)
      fillInput($form.node('event[leader_energy]'), record.leader_energy)
      fillInput($form.node('event[leader_uniform]'), record.leader_uniform)
      fillInput($form.node('event[leader_food]'), record.leader_food)
      fillInput($form.node('event[leader_transport]'), record.leader_transport)
      fillInput($form.node('event[shift_start_time]'), record.shift_start_time)

    @leadersForm = new RecordEditForm(@viewport.find('.record-edit #event-leaders #event-leaders-form'), @, fillInLeadersForm)

    fillInAccomodationForm = ($form, record) ->
      fillInput($form.node('event[accom_status]'), record.accom_status)
      fillInput($form.node('event[accom_room_info]'), record.accom_room_info)
      fillInput($form.node('event[accom_hotel_name]'), record.accom_hotel_name)
      fillInput($form.node('event[accom_address]'), record.accom_address)
      fillInput($form.node('event[accom_distance]'), record.accom_distance)
      fillInput($form.node('event[accom_phone]'), record.accom_phone)
      fillInput($form.node('event[accom_booking_dates]'), record.accom_booking_dates)
      fillInput($form.node('event[accom_parking]'), record.accom_parking)
      fillInput($form.node('event[accom_wifi]'), record.accom_wifi)
      fillInput($form.node('event[accom_booking_ref]'), record.accom_booking_ref)
      fillInput($form.node('event[accom_booking_via]'), record.accom_booking_via)
      fillDateInput($($form.node('event[accom_refund_date]')), record.accom_refund_date)
      fillInput($form.node('event[accom_cancellation_policy]'), record.accom_cancellation_policy)
      fillInput($form.node('event[accom_total_cost]'), record.accom_total_cost)
      fillInput($form.node('event[accom_payment_method]'), record.accom_payment_method)
      fillInput($form.node('event[accom_booked_by]'), record.accom_booked_by)
      fillInput($form.node('event[accom_notes]'), record.accom_notes)

    @accomodationForm = new RecordEditForm(@viewport.find('.record-edit #event-accomodation'), @, fillInAccomodationForm)

    expenseColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true},
      {name: 'Name',  id: 'name'},
      {name: 'Cost',  id: 'cost'},
      {name: 'Notes', id: 'notes'},
      {name: 'Del', sortable: false}]
    expenseRowBuilder = (expense) =>
      eventId = expense.event_id || @editForm.editingId()
      [ buildHiddenInput('event_id', eventId),
        buildTextInput({name: "[expenses][" + expense.id + "][name]", value: expense.name, otherHtml: "id='expense_"+expense.id+"_name'"}),
        buildTextInput({name: "[expenses][" + expense.id + "][cost]", value: (if expense.cost != null then Number(expense.cost).toFixed(2) else '')}),
        buildAutosizeTextarea({name: "[expenses][" + expense.id + "][notes]", value: expense.notes}),
        buildDeleteLink(expense.id, 'delete_expense')]
    @expensesTable = new EditableListView(@db, @viewport.find('#event-expenses'), 'expenses', expenseColumns, expenseRowBuilder,
      Actor(
        save: (data) =>
          @saveChanges('/office/update_expenses', data.data, data.actor)
        clean: => @clean()
        dirty: => @dirty()))
    @expensesTable.displayBlankRow({id: -1, name: '', cost: null, notes: ''})
    @expensesTable.sortOnColumn('name', true)

    fillInExpensesForm = (form, record) ->
      form.find('#event_expense_notes').val(record.expense_notes)
      form.find('#event_post_notes').val(record.post_notes)

    @expensesForm = new RecordEditForm(@viewport.find('.record-edit #event-expenses .expenses-form'), @, fillInExpensesForm)
    $('.nav-tabs a[href="#event-expenses"]').on('shown.bs.tab', (e) -> autosize.update($('#event-expenses').find('textarea')))

    fillInDefaultJobForm = (form, record) =>
      jobs = @db.queryAll('jobs', {event_id: record.id}, 'name')
      jobs = [['', '']].concat(jobs.map((job) -> [job.name, job.id]))
      form.find('#event_default_job_id').html(buildOptions(jobs, record.default_job_id))

    @defaultJobForm = new RecordEditForm(@viewport.find('.record-edit #event-jobs .job-form'), @, fillInDefaultJobForm)

    fillInDefaultLocationForm = (form, record) =>
      locations = @db.queryAll('locations', {event_id: record.id}, 'name')
      locations = [['', '']].concat(locations.map((location) -> [location.name, location.id]))
      form.find('#event_default_location_id').html(buildOptions(locations, record.default_location_id))

    @defaultLocationForm = new RecordEditForm(@viewport.find('.record-edit #event-locations .location-form'), @, fillInDefaultLocationForm)

    jobColumns = [
      {id: 'event_id',               name: 'Event ID', hidden: true},
      {id: 'name',                   name: 'Name'},
      {id: 'pay_17_and_under',       name: '£ -17'},
      {id: 'pay_18_and_over',        name: '£ 18-20'},
      {id: 'pay_21_and_over',        name: '£ 21-22'},
      {id: 'pay_25_and_over',        name: '£ 23+'},
      {id: 'include_in_description', name: 'Public?'},
      {name: 'Featured'},
      {id: 'public_name',            name: 'Public Name'},
      {id: 'number_of_positions',    name: 'Number of Jobs'},
      {id: 'description',            name: 'Job Requirement'},
      {name: 'Del', sortable: false}]
    jobRowBuilder = (job) =>
      eventId = job.event_id || @editForm.editingId()
      event = @db.queryAll('events', {id: eventId})[0]
      featured_job_checked = ''
      if event
        if event.featured_job == job.id
          featured_job_checked = "checked"

      [ buildHiddenInput('event_id', eventId),
        buildTextInput({name: "[jobs]["+job.id+"][name]", value: job.name, otherHtml: "id='job_"+job.id+"_name'"}),
        buildTextInput({name: "[jobs][" + job.id + "][pay_17_and_under]", value: job.pay_17_and_under}),
        buildTextInput({name: "[jobs][" + job.id + "][pay_18_and_over]", value: job.pay_18_and_over}),
        buildTextInput({name: "[jobs][" + job.id + "][pay_21_and_over]", value: job.pay_21_and_over}),
        buildTextInput({name: "[jobs][" + job.id + "][pay_25_and_over]", value: job.pay_25_and_over}),
        buildCheckbox({class: "hire-checkbox v2_job_public", name: "[jobs][" + job.id + "][include_in_description]", checked: job.include_in_description}),
        buildCheckbox({class: "hire-checkbox v2_job_featured", name: "[jobs][" + job.id + "][featured_job]", checked: featured_job_checked}),
#        "<input type='checkbox' class='hire-checkbox v2_job_public' name='[jobs][" + job.id + "][include_in_description]'"  + (if job.include_in_description then " checked='checked'" else '') + "'>",
#        "<input type='checkbox' class='hire-checkbox v2_job_featured' name='[jobs][" + job.id + "][featured_job]'" + featured_job_checked + "'>",
        buildTextInput({name: "[jobs][" + job.id + "][public_name]", value: (job.public_name || '')}),
        buildTextInput({name: "[jobs][" + job.id + "][number_of_positions]", value: (job.number_of_positions || 0)}),
        buildAutosizeTextarea({name: "[jobs][" + job.id + "][description]", value: job.description}),
        buildDeleteLink(job.id, 'delete_job')]
    @jobsTable = new EditableListView(@db, @viewport.find('#event-jobs'), 'jobs', jobColumns, jobRowBuilder, Actor(
      save: (data) =>
        @saveChanges('/office/update_jobs', data.data, data.actor)
      clean: => @clean()
      dirty: => @dirty()))
    @jobsTable.displayBlankRow({id: -1, name: '', pay_17_and_under: '8.0', pay_18_and_over: '', pay_21_and_over: '', pay_25_and_over: '', include_in_description: true})
    @jobsTable.sortOnColumn('name', true)
    $('.nav-tabs a[href="#event-jobs"]').on('shown.bs.tab', (e) -> autosize.update($('#event-jobs').find('textarea')))

    shiftColumns = [
      {name: 'Event Id', id: 'event_id', hidden: true},
      {name: 'Name', sortable: false},
      {id: 'date',       name: 'Date', type: 'date', sortable: false},
      {id: 'time_start', name: 'Start', sortable: false},
      {id: 'time_end',   name: 'End', sortable: false},
      {name: 'Del', sortable: false}]
    shiftRowBuilder = (shift) =>
      eventId = shift.event_id || @editForm.editingId()
      today_date = new Date();
      $date_field = $("<input type='text' class='form-control' name='[shifts][" + shift.id + "][date]' value='" + printDateWithDOW(shift.date) + "' placeholder='DD/MM/YYYY'></input>")
      if event = @db.findId('events', eventId)
        setUpDatepicker($date_field, 'D dd/mm/yy', event.public_date_start.getMonth() - today_date.getMonth() + "m'")
        enableDatesOnDatePicker($date_field, event.event_dates['ALL'].map((event_date) -> event_date.date))
      else
        setUpDatepicker($date_field, 'D dd/mm/yy')
      fillDateInput($date_field, (shift.date || ''))

      [ buildHiddenInput('event_id', eventId),
        (if shift.id == -1 then '' else printShift(shift)),
        $date_field,
        buildTextInput({name: "[shifts][" + shift.id + "][time_start]", value: shift.time_start, otherHtml: "placeholder='HH:MM'"}),
        buildTextInput({name: "[shifts][" + shift.id + "][time_end]",   value: shift.time_end,   otherHtml: "placeholder='HH:MM'"}),
        buildDeleteLink(shift.id, 'delete_shift')]

    @shiftsTable = new EditableListView(@db, @viewport.find('#event-shifts'), 'shifts', shiftColumns, shiftRowBuilder,
      Actor(
        save: (args) =>
          @saveChanges('/office/update_shifts', args.data, args.actor)
        clean: => @clean()
        dirty: => @dirty()),
        shiftSort)
    @shiftsTable.displayBlankRow({id: -1, name: '', time_start: '', time_end: '', date: ''})

    tagColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true}
      {name: 'Name', id: 'name'},
      {name: 'Del', sortable: false}]
    tagRowBuilder = (tag) =>
      eventId = tag.event_id || @editForm.editingId()
      [buildHiddenInput('event_id', eventId),
        buildTextInput({name: "[tags][" + tag.id + "][name]", value: tag.name, otherHtml: "id='tag_" + tag.id + "_name'"}),
        buildDeleteLink(tag.id, 'delete_tag')]

    @tagsTable = new EditableListView(@db, @viewport.find('#event-tags'), 'tags', tagColumns, tagRowBuilder, Actor(
      save: (data) =>
        @saveChanges('/office/update_tags', data.data, data.actor)
      clean: => @clean()
      dirty: => @dirty()))
    @tagsTable.displayBlankRow({id: -1, name: '', cost: 0})
    @tagsTable.sortOnColumn('name', true)

    locationColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true},
      {name: 'Name',  id: 'name', sortable: false},
      {name: 'Type',  id: 'type', sortable: false},
      {name: 'Del', sortable: false}]
    locationRowBuilder = (location) =>
      eventId = location.event_id || @editForm.editingId()

      [ buildHiddenInput('event_id', eventId),
        buildTextInput({name: "[locations]["+location.id+"][name]", value: location.name, otherHtml: "id='location_"+location.id+"_name'"}),
        buildSelect({name: "[locations][" + location.id + "][type]", options: [['Regular','REGULAR'],['Floater', 'FLOATER'],['Spare','SPARE']], selected: location.type}),
        buildDeleteLink(location.id, 'delete_location')]
    @locationsTable = new EditableListView(@db, @viewport.find('#event-locations'), 'locations', locationColumns, locationRowBuilder,
      Actor(
        save: (data) =>
          @saveChanges('/office/update_locations', data.data, data.actor)
        clean: => @clean()
        dirty: => @dirty())
      locationSort)
    @locationsTable.displayBlankRow({id: -1, name: ''})

    fillInDefaultAssignmentForm = (form, record) =>
      assignments = @db.queryAll('assignments', {event_id: record.id}, assignmentSort)
      assignmentOptions = [['', '']].concat(assignments.map((assignment) -> [printAssignment(assignment), assignment.id]))
      form.find('#event_default_assignment_id').html(buildOptions(assignmentOptions, record.default_assignment_id))

    @defaultAssignmentForm = new RecordEditForm(@viewport.find('.record-edit #event-assignments .default-assignment-form'), @, fillInDefaultAssignmentForm)

    assignmentColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true},
      {name: 'Job',  id: 'job_id', sortable: false},
      {name: 'Shift', id: 'shift_id', sortable: false},
      {name: 'Work Area', id: 'location_id', sortable: false},
      {name: '# Needed', id: 'staff_needed', sortable: false}
      {name: '# Confirmed', id: 'n_confirmed', sortable: false}
      {name: '# Assigned', id: 'n_assigned', sortable: false}
      {name: 'Del', sortable: false}]
    assignmentRowBuilder = (assignment) =>
      eventId = assignment.event_id || @editForm.editingId()
      taxWeekId = getDropdownIntVal(@viewport.find('#assignments-tax-week-dropdown'))
      date = getDropdownDateVal(@viewport.find('#assignments-date-dropdown'))
      filteredJobId = getDropdownIntVal(@viewport.find('#assignments-job-dropdown'))
      filteredShiftId = getDropdownIntVal(@viewport.find('#assignments-shift-dropdown'))
      filteredLocationId = getDropdownIntVal(@viewport.find('#assignments-location-dropdown'))
      jobOptions = if filteredJobId then [['',''],[@db.findId("jobs", filteredJobId).name, filteredJobId]] else @jobOptions(eventId)
      shiftOptions = if filteredShiftId then [['',''],[printShift(@db.findId("shifts", filteredShiftId)), filteredShiftId]] else [['','']].concat(@shiftOptions(eventId, taxWeekId, date))
      locationOptions = if filteredLocationId then [['',''],[printLocation(@db.findId("locations", filteredLocationId)), filteredLocationId]] else @locationOptions(eventId)

      [ buildHiddenInput('event_id', eventId),
        buildSelect({name: "[assignments][" + assignment.id + "][job_id]", options: jobOptions, selected: assignment.job_id, class: "jobs-dropdown"}),
        buildSelect({name: "[assignments][" + assignment.id + "][shift_id]", options: shiftOptions, selected: assignment.shift_id, class: "shifts-dropdown"}),
        buildSelect({name: "[assignments][" + assignment.id + "][location_id]", options: locationOptions, selected: assignment.location_id, class: "locations-dropdown"}),
        buildTextInput({name: "[assignments][" + assignment.id + "][staff_needed]", value: assignment.staff_needed}),
        assignment.n_confirmed,
        assignment.n_assigned,
        buildDeleteLink(assignment.id, 'delete_assignment')]
    @assignmentsTable = new EditableListView( @db, @viewport.find('#event-assignments'), 'assignments', assignmentColumns, assignmentRowBuilder,
      Actor(
        save: (data) =>
          @saveChanges('/office/update_assignments', data.data, data.actor)
        clean: => @clean()
        dirty: => @dirty()),
      assignmentSort)
    @assignmentsTable.displayBlankRow({id: -1, job_id: '', shift_id: '', location_id: '', staff_needed: '', n_confirmed: '0', n_assigned: 0})

    eventTaskColumns = [
      {name: 'Event ID', id: 'event_id', hidden: true},
      {name: 'Due Date', id: 'due_date'},
      {name: 'Done?',    id: 'completed'},
      {name: 'Task',     id: 'template_id'},
      {name: 'W2Live',   id: 'weeks_to_live', virtual: true}
      {name: 'Notes',    id: 'notes'},
      {name: 'Manager notes',    id: 'additional_notes'},
      {name: 'Who',      id: 'officer_id'},
      {name: '2nd Who',      id: 'second_officer_id'},
      {name: 'Del',      sortable: false}
    ]

    eventTaskRowBuilder = (eventTask) =>
      eventId = eventTask.event_id || @editForm.editingId()

      $dateField = $("<input type='text' class='form-control' name='[event_tasks][" + eventTask.id + "][due_date]' value='" + printDateWithDOW(eventTask.due_date) + "' placeholder='DD/MM/YYYY'></input>")
      setUpDatepicker($dateField, 'D dd/mm/yy')
      fillDateInput($dateField, (eventTask.due_date || ''))

      officerOptions = @getActiveOperationalManagerOptions(eventTask.officer_id)
      secondOfficerOptions = @getSecondActiveOperationalManagerOptions(eventTask.second_officer_id)
      options = [['Custom','']]
      taskOptions = options.concat(@db.queryAll('event_task_templates', {}, 'task').map((ett) -> [ett.task, ett.id]))
      event = @db.findId('events', eventId)
      if event
        countdown = getEventWeekCountdown(event.date_start, eventTask.due_date)
        selected_officer = eventTask.officer_id || event.office_manager_id
      else
        selected_officer = eventTask.officer_id

      [buildHiddenInput('event_id', eventId),
        $dateField,
        buildCheckbox({name: "[event_tasks][" + eventTask.id + "][completed]", checked: eventTask.completed }),
        buildSelect({name: "[event_tasks][" + eventTask.id + "][template_id]", options: taskOptions, selected: eventTask.template_id, class: "templates-dropdown"}),
        countdown || "",
        buildAutosizeTextarea({name: "[event_tasks][" + eventTask.id + "][notes]", value: eventTask.notes, otherHtml: "id='event_task_" + eventTask.id + "_notes'"}),
        buildTextInput({name: "[event_tasks][" + eventTask.id + "][additional_notes]", value: eventTask.additional_notes}),
        buildSelect({name: "[event_tasks][" + eventTask.id + "][officer_id]", options: [['','']].concat(officerOptions), selected: selected_officer, class: "officers-dropdown"}),
        buildSelect({name: "[event_tasks][" + eventTask.id + "][second_officer_id]", options: [['','']].concat(secondOfficerOptions), selected: eventTask.second_officer_id, class: "second-officers-dropdown"}),
        buildDeleteLink(eventTask.id, 'delete_event_task')]

    @eventTasksTable = new EditableListView(@db, @viewport.find('#event-tasks'), 'event_tasks', eventTaskColumns, eventTaskRowBuilder, Actor(
      save: (data) =>
        @saveChanges('/office/update_event_tasks_from_event', data.data, data.actor)
      clean: => @clean()
      dirty: => @dirty()))
    @eventTasksTable.displayBlankRow({id: -1, due_date: '', officer_id: '', completed: false, task: '', notes: '', event_id: event.id})
    @eventTasksTable.sortOnColumn('due_date', true)

    @displayedTab = 'event-details'
    @viewport.find('.record-edit .slideover-tabs a').click((event) =>
      event.preventDefault()
      link   = $(event.target)
      newTab = link.attr('href').slice(1)
      if newTab != @displayedTab
        @tryToSave(=>
          @displayedTab = newTab
          link.tab('show')
          @refreshForm()))

    # apply default 'Upcoming' filter
    @filter({filters: @filterBar.selectedFilters()})

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

    #Redraw main table first to ensure that any other tables that rely on @table.selectedRecord have the latest data
    @db.onUpdate(['events'], =>
      EventsView::updateStatistics()
      @redraw())
    @db.onUpdate('locations', =>
      if @editForm.in()
        @locationsTable.draw()
        # This 'markClean' is problematic...
        # If the user was in the middle of editing a record when new data comes,
        #   the record he was editing is 'marked clean' and won't be auto-saved!
        @locationsTable.markClean()
        @updateLocationDropdowns()
      if eventId = @defaultLocationForm.editingId()
        @defaultLocationForm.stopEditing()
        @defaultLocationForm.editRecord(@db.findId('events', eventId)))
    @db.onUpdate('tags', =>
      if @editForm.in()
        @tagsTable.draw()
        @tagsTable.markClean())
    @db.onUpdate('event_tasks', =>
      if @editForm.in()
        @eventTasksTable.draw()
        @eventTasksTable.markClean())
    @db.onUpdate('team_leader_roles', =>
      if @editForm.in()
        @leadersTable.draw()
        @leadersTable.markClean()
        if eventId = @leadersForm.editingId()
          @leadersForm.stopEditing()
          @leadersForm.editRecord(@db.findId('events', eventId)))
    @db.onUpdate('expenses', =>
      if @editForm.in()
        @expensesTable.draw()
        @expensesTable.markClean()
        if eventId = @expensesForm.editingId()
          @expensesForm.stopEditing()
          @expensesForm.editRecord(@db.findId('events', eventId)))
    @db.onUpdate('jobs', =>
      if @editForm.in()
        @jobsTable.draw()
        @jobsTable.markClean()
        @updateJobDropdowns()
        if eventId = @defaultJobForm.editingId()
          @defaultJobForm.stopEditing()
          @defaultJobForm.editRecord(@db.findId('events', eventId)))
    @db.onUpdate(['events', 'shifts', 'event_dates'], =>
      EventsView::updateStatistics()
      if @editForm.in()
        @shiftsTable.draw()
        @shiftsTable.refreshBlanks() #update DatePicker
        @shiftsTable.markClean()
        @updateShiftDropdowns()
        @updateAssignmentDateDropdown()
        @updateShiftDateDropdown())
    @db.onUpdate(['assignments', 'shifts', 'jobs', 'locations'], =>
      EventsView::updateStatistics()
      if @editForm.in()
        @assignmentsTable.draw()
        @assignmentsTable.markClean())
    @db.onUpdate('assignments', =>
      EventsView::updateStatistics()
      #update the 'Default Assignment' dropdown
      if eventId = @defaultAssignmentForm.editingId()
        @defaultAssignmentForm.stopEditing()
        @defaultAssignmentForm.editRecord(@db.findId('events', eventId)))
    @db.onUpdate('officers', =>
      @updateOfficerDropdowns('.filter-bar .active-operational-managers-dropdown', [['',''],['None', -1]])
      @updateOfficerSeniorManagerDropdowns('.filter-bar .active-senior-managers-dropdown', [['',''],['None', -1]])
      @updateOfficerDropdowns('#edit_event .active-operational-managers-dropdown', [['','']])
      @updateOfficerSeniorManagerDropdowns('#edit_event .active-senior-managers-dropdown', [['','']])
    )

    $('.clear-event-tasks').on 'click', ->
      alert = confirm("Are you sure?. It will remove all the tasks of selected event from event tab and planner tab?")
      if alert == true
        ServerProxy.saveChanges("/office/remove_event_tasks/"+$(this).val(), {id: $(this).val()}, Actor(
          requestSuccess: =>
            editFormRemoveTasks.node('event[size_id]').value = ''
            window.db.refreshData()
        ), window.db)


  # Note: the dropdowns in the tables already take care of their own updating.
  #       These just update the filters and blank rows

  updateJobDropdowns: ->
    if @eventId?
      options = buildOptions(@jobOptions(@eventId))
      @viewport.find('.blank .jobs-dropdown, .filter-bar .jobs-dropdown').each((i,select) =>
        $select = $(select)
        val = $select.val()
        $select.html(options).val(val))

  updateLocationDropdowns: ->
    if @eventId?
      options = buildOptions(@locationOptions(@eventId))
      @viewport.find('.blank .locations-dropdown, .filter-bar .locations-dropdown').each((i,select) =>
        $select = $(select)
        val = $select.val()
        $select.html(options).val(val))

  updateShiftDropdowns: ->
    if @eventId?
      options = [['','']].concat(@shiftOptions(@eventId, getDropdownIntVal(@viewport.find('#assignments-tax-week-dropdown')), getDropdownDateVal(@viewport.find('#assignments-date-dropdown'))))
      @viewport.find('.blank .shifts-dropdown, .filter-bar .shifts-dropdown').each((i,select) =>
        $(select).html(buildOptions(options, parseInt($(select).val(), 10))))

  updateOfficerDropdowns: (selector, base_options, officer_id = null) ->
    options = base_options.concat(@getActiveOperationalManagerOptions(officer_id))
    @viewport.find(selector).each((i,select) =>
      officer_id ||= parseInt($(select).val(), 10)
      $(select).html(buildOptions(options, officer_id)))

  updateOfficerSeniorManagerDropdowns: (selector, base_options, officer_id = null) ->
    options = base_options.concat(@getSeniorManagerOptions(officer_id))
    @viewport.find(selector).each((i,select) =>
      officer_id ||= parseInt($(select).val(), 10)
      $(select).html(buildOptions(options, officer_id)))

  updateAssignmentDateDropdown: ->
    if @eventId?
      @viewport.find('.dates-dropdown').each((i,select) =>
        $(select).html(buildOptions([['','']].concat(
          @dateOptions(@eventId, getDropdownIntVal(@viewport.find('#assignments-tax-week-dropdown')))), $(select).val())))

  updateShiftDateDropdown: ->
    if @eventId?
      @viewport.find('#shifts-date-dropdown').each((i,select) =>
        $(select).html(buildOptions([['','']].concat(
          @dateOptions(@eventId, getDropdownIntVal(@viewport.find('#shifts-tax-week-dropdown')))), $(select).val())))

  jobOptions: (eventId) ->
    options = @db.queryAll('jobs', {event_id: eventId}, 'name').map((object) -> [object.name, object.id])
    [['', '']].concat(options)

  locationOptions: (eventId) ->
    options = @db.queryAll('locations', {event_id: eventId}, locationSort).map((object) -> [printLocation(object), object.id])
    [['', '']].concat(options)

  shiftOptions: (eventId, taxWeekId, date) =>
    filter = {event_id: eventId}
    if date
      filter['date'] = date
    else
      filter['tax_week_id'] = taxWeekId if taxWeekId
    shifts = @db.queryAll('shifts', filter, shiftSort)
    shifts.map((shift) -> [printShift(shift), shift.id])

  dateOptions: (eventId, taxWeekId) =>
    filter = {event_id: eventId}
    filter['tax_week_id'] = taxWeekId if taxWeekId
    shifts = @db.queryAll('shifts', filter, shiftSort)
    dates = []
    date_vals = []
    for shift in shifts
      time = shift.date.getTime()
      if date_vals.indexOf(time) < 0
        dates.push(shift.date)
        date_vals.push(time)
    dates.map((date) -> [printDate(date), date.toString()])

  updateStatistics: =>
    totalNoOfEvents = window.db.queryAll('events', {created_this_year: true}).length
    totalNoOfProspects = window.db.queryAll('prospects', {created_this_year: true, status: 'EMPLOYEE'}).length
    totalNoOfJobs = window.db.queryAll('assignments', {created_this_year: true}).length
    $('.no-of-events').html(totalNoOfEvents)
    $('.no-of-prospects').html(totalNoOfProspects)
    $('.no-of-jobs').html(totalNoOfJobs)

  # We have tax week "filters" on the assignments and shifts tab
  updateTaxWeekDropdowns: ->
    if @eventId?
      event = @db.findId('events', @eventId)
      tax_weeks = @db.queryAll('tax_weeks', {overlaps_dates: [event.date_start, event.date_end] })
      options = tax_weeks.map((tw) -> [printTaxWeek(tw), tw.id])
      @viewport.find('.tax-week-dropdown').each((i,select) ->
        tax_week = getDefaultTaxWeekForEvent(event)
        defaultVal = if tax_week? then tax_week.id else ''
        $(select).html(buildOptions([['', '']].concat(options), defaultVal)).change())

  draw: ->
    if @shownSubview == 'table'
      @table.draw()
      rebind(@viewport.find('.event-admin-completed'), 'change', @adminCheckboxHandler)
    else
      @map.draw()

  adminCheckboxHandler: (event) =>
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
        @leadersForm.stopEditing()
        @accomodationForm.stopEditing()
        @expensesForm.stopEditing()
        @bookingForm.stopEditing()
        @defaultJobForm.stopEditing()
        @defaultLocationForm.stopEditing()
        @defaultAssignmentForm.stopEditing()
        @viewport.find('.record-edit a[href="#event-details"]').tab('show')
        @displayedTab = 'event-details'
      @newForm.newRecord())

  newRecordBooking: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @leadersForm.stopEditing()
        @accomodationForm.stopEditing()
        @expensesForm.stopEditing()
        @bookingForm.stopEditing()
        @defaultJobForm.stopEditing()
        @defaultLocationForm.stopEditing()
        @defaultAssignmentForm.stopEditing()
        @viewport.find('.record-edit a[href="#event-details"]').tab('show')
        @displayedTab = 'event-details'
      @newBookingForm.newRecord())

  editSelectedRecord: ->
    if record = @table.selectedRecord()
      @tryToSave(=>
        if @newForm.in()
          @newForm.stopEditing()
        if @newBookingForm.in()
          @newBookingForm.stopEditing()
        @editRecord(record))

  revert: ->
    if @editForm.in()
      switch @displayedTab
        when 'event-details'    then @editForm.revert()
        when 'event-jobs'
          @jobsTable.revert()
          @defaultJobForm.revert()
          @defaultLocationForm.revert()
          @defaultAssignmentForm.revert()
        when 'event-shifts'     then @shiftsTable.revert()
        when 'event-locations'  then @locationsTable.revert()
        when 'event-tags'       then @tagsTable.revert()
        when 'event-assignments' then @assignmentsTable.revert()
        when 'event-leaders'
          @leadersTable.revert()
          @leadersForm.revert()
        when 'event-accomodation' then @accomodationForm.revert()
        when 'event-expenses'
          @expensesTable.revert()
          @expensesForm.revert()
        when 'event-booking' then @bookingForm.revert()
        when 'event-tasks' then @eventTasksTable.revert()
    else if @newForm.in()
      @newForm.revert()
    else if @newBookingForm.in()
      @newBookingForm.revert()

  deleteRecord: ->
    url = if @editForm.in()
      switch @displayedTab
        when 'event-jobs'
          if (record = @jobsTable.selectedRecord()) && record.id != -1
            '/office/delete_job/' + record.id
        when 'event-shifts'
          if (record = @shiftsTable.selectedRecord()) && record.id >= 0
            '/office/delete_shift/' + record.id
        when 'event-leaders'
          if (record = @leadersTable.selectedRecord()) && record.id >= 0
             '/office/delete_team_leader_role/' + record.id
        when 'event-shifts'
          if (record = @expensesTable.selectedRecord()) && record.id >= 0
            '/office/delete_expense/' + record.id
        when 'event-locations'
          if (record = @locationsTable.selectedRecord()) && record.id != -1
            '/office/delete_location/' + record.id
        when 'event-assignments'
          if (record = @assignmentsTable.selectedRecord()) && record.id != -1
            '/office/delete_assignment/' + record.id
        when 'event-tags'
          if (record = @tagsTable.selectedRecord()) && record.id != -1
            '/office/delete_tag/' + record.id
        when 'event-tasks'
          if (record = @eventTasksTable.selectedRecord()) && record.id != -1
            '/office/delete_event_task/' + record.id
        when 'event-details', 'event-accomodation'
          if record = @table.selectedRecord()
            '/office/delete_event/' + record.id
    else if record = @table.selectedRecord()
      '/office/delete_event/' + record.id

    ServerProxy.sendRequest(url, {}, ErrorOnlyPopup, @db)

  duplicatePartial: ->
    @duplicateRecord()

  duplicateFull: ->
    @duplicateRecord({duplicate_full: true})

  duplicateRecord: (params) ->
    if record = @table.selectedRecord()
      ServerProxy.sendRequest('/office/duplicate_event/'+record.id, params, Actor(
          requestSuccess: (data) =>
            @tryToSave(=>
              if @editForm.in()
                @editForm.stopEditing()
                @leadersForm.stopEditing()
                @accomodationForm.stopEditing()
                @expensesForm.stopEditing()
                @bookingForm.stopEditing()
                @defaultJobForm.stopEditing()
                @defaultLocationForm.stopEditing()
                @defaultAssignmentForm.stopEditing()
                @viewport.find('.record-edit a[href="#event-details"]').tab('show')
                @displayedTab = 'event-details'
              #for table,records of data.result.tables when records.length > 0
              new_record = @db.findId('events', data.result.new_id)
              @table.selectRecord(new_record)
              @editRecord(new_record)
              @refreshForm())
          requestError: (data) =>
            NotificationPopup.requestError(data)), @db)

  uploadPhoto: ->
    @viewport.find('.popover form').fileupload({
      url: '/office/upload_event_photo/' + @table.selectedRecord().id,
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

  createSimpleTestEvent: ->
    ServerProxy.saveChanges('/office/create_test_event', {type: 'Simple'}, Actor(
      requestSuccess: =>
        @db.refreshData()
    ), @db)

  createTestEvent: ->
    ServerProxy.saveChanges('/office/create_test_event', {}, Actor(
      requestSuccess: =>
        @db.refreshData()
    ), @db)

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
        @leadersForm.stopEditing()
        @accomodationForm.stopEditing()
        @expensesForm.stopEditing()
        @bookingForm.stopEditing()
        @defaultJobForm.stopEditing()
        @defaultLocationForm.stopEditing()
        @defaultAssignmentForm.stopEditing()
        @viewport.find('.record-edit a[href="#event-details"]').tab('show')
        @displayedTab = 'event-details')
    else if @newForm.in()
      @tryToSave(=> @newForm.stopEditing(); @editRecord(data.record))
    else if @newBookingForm.in()
      @tryToSave(=> @newBookingForm.stopEditing(); @editRecord(data.record))
    else
      @editRecord(data.record)

  saveAndClose: ->
    @tryToSave(=>
      if @editForm.in()
        @editForm.stopEditing()
        @leadersForm.stopEditing()
        @accomodationForm.stopEditing()
        @expensesForm.stopEditing()
        @bookingForm.stopEditing()
        @defaultJobForm.stopEditing()
        @defaultLocationForm.stopEditing()
        @defaultAssignmentForm.stopEditing()
        @viewport.find('.record-edit a[href="#event-details"]').tab('show')
        @displayedTab = 'event-details'
      else if @newForm.in()
        @newForm.stopEditing()
      else if @newBookingForm.in()
        @newBookingForm.stopEditing())

  close: ->
    if @editForm.in()
      @editForm.stopEditing()
      @leadersForm.stopEditing()
      @accomodationForm.stopEditing()
      @expensesForm.stopEditing()
      @bookingForm.stopEditing()
      @defaultJobForm.stopEditing()
      @defaultLocationForm.stopEditing()
      @jobsTable.revert()
      @shiftsTable.revert()
      @locationsTable.revert()
      @assignmentsTable.revert()
      @leadersTable.revert()
      @expensesTable.revert()
      @tagsTable.revert()
      @eventTasksTable.revert()
      @viewport.find('.record-edit a[href="#event-details"]').tab('show')
      @displayedTab = 'event-details'
    else if @newForm.in()
      @newForm.stopEditing()
    else if @newBookingForm.in()
      @newBookingForm.stopEditing()

  postSlideIn: ->
    if @editForm.in()
      @refreshEventCalendar()
      autosize.update(@viewport.find('.record-edit textarea'))
    else if @newForm.in()
      autosize.update(@viewport.find('.record-new textarea'))
    else if @newBookingForm.in()
      autosize.update(@viewport.find('.record-new-booking textarea'))

  saveAll: (options) ->
    if @newForm.in()
      @tryToSave(=>
        if record = @db.queryAll('events', {name: @newForm.node('event[name]').value})[0]
          @newForm.stopEditing()
          @table.selectRecord(record)
          @editRecord(record))
    else if @newBookingForm.in()
      @tryToSave(=>
        if record = @db.queryAll('events', {name: @newBookingForm.node('event[name]').value})[0]
          @newBookingForm.stopEditing()
          @table.selectRecord(record)
          @editRecord(record)
          @viewport.find('.record-edit a[href="#event-booking"]').tab('show')
          @displayedTab = 'event-booking')
    else
      @tryToSave(=>
        @refreshForm() unless options.skip_refresh)

  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  refreshForm: () ->
    @bookingForm.refreshForm(@db, 'events')
    @editForm.refreshForm(@db, 'events')

  tryToSave: (callback) ->
    actor = Actor({saved: callback})
    if @editForm.in()
      switch @displayedTab
        when 'event-jobs'
          if @defaultJobForm.isDirty()
            @defaultJobForm.saveRecord('/office/update_event/', @db, Actor(
              saved: => @jobsTable.save(actor)), 'event')
          else
            @jobsTable.save(actor)
        when 'event-shifts'      then @shiftsTable.save(actor)
        when 'event-locations'
          if @defaultLocationForm.isDirty()
            @defaultLocationForm.saveRecord('/office/update_event/', @db, Actor(
              saved: => @locationsTable.save(actor)), 'event')
          else
            @locationsTable.save(actor)
        when 'event-assignments'
          if @defaultAssignmentForm.isDirty()
            @defaultAssignmentForm.saveRecord('/office/update_event/', @db, Actor(
              saved: => @assignmentsTable.save(actor)), 'event')
          else
            @assignmentsTable.save(actor)
        when 'event-tags'        then @tagsTable.save(actor)
        when 'event-tasks'       then @eventTasksTable.save(actor)
        when 'event-leaders'
          if @leadersForm.isDirty()
            @leadersForm.saveRecord('/office/update_event/', @db, actor, 'event')
          else
            callback()
        when 'event-accomodation'
          if @accomodationForm.isDirty()
            @accomodationForm.saveRecord('/office/update_event/', @db, actor, 'event')
          else
            callback()
        when 'event-expenses'
          if @expensesForm.isDirty()
            @expensesForm.saveRecord('/office/update_event/', @db, Actor(
              saved: => @expensesTable.save(actor)), 'event')
          else
            @expensesTable.save(actor)
        when 'event-booking'
          if @bookingForm.isDirty()
            @bookingForm.saveRecord('/office/update_event/', @db, actor, 'event')
          else
            callback()
        when 'event-details'
          if @editForm.isDirty()
            @editForm.saveRecord('/office/update_event/', @db, actor, 'event')
          else
            callback()
    else if @newForm.in() && @newForm.isDirty()
      @newForm.saveRecord('/office/create_event/', @db, actor, 'event')
    else if @newBookingForm.in() && @newBookingForm.isDirty()
      @newBookingForm.saveRecord('/office/create_event/', @db, actor, 'event')
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
    @eventId = record.id
    @jobsTable.filter({filters: {event_id: record.id}})
    @locationsTable.filter({filters: {event_id: record.id}})
    @tagsTable.filter({filters: {event_id: record.id}})
    @eventTasksTable.filter({filters: {event_id: record.id}})
    @shiftsTable.filter({filters: {event_id: record.id}})
    @shiftsTable.refreshBlanks() #update DatePicker
    @assignmentsTable.filter({filters: {event_id: record.id}})
    @leadersTable.filter({filters: {event_id: record.id}})
    @expensesTable.filter({filters: {event_id: record.id}})

    @updateTaxWeekDropdowns()
    @updateJobDropdowns()
    @updateShiftDropdowns()
    @updateAssignmentDateDropdown()
    @updateShiftDateDropdown()
    @updateLocationDropdowns()

    @viewport.find('input[name="event_id"]').val(record.id)

    @editForm.editRecord(record)
    @accomodationForm.editRecord(record)
    @leadersForm.editRecord(record)
    @expensesForm.editRecord(record)
    @defaultJobForm.editRecord(record)
    @defaultLocationForm.editRecord(record)
    @defaultAssignmentForm.editRecord(record)

    if record.status == 'BOOKING'
      @viewport.find('.record-edit a[href="#event-booking"]').tab('show')
      @displayedTab = 'event-booking'
    @bookingForm.editRecord(record)

  numRows: (numRows) =>
    @table.pageSize(numRows)
    @table.draw()

  ######################
  ##### Event Days #####
  ######################

  refreshEventCalendar: =>
    if $form = @getForm()
      $calendar = $form.find('#edit_event_calendar')
      $calendar.multiDatesPicker('resetDates', 'picked')
      $calendar.multiDatesPicker('destroy')
      event = @db.findId('events', @eventId)
      if event.date_start && event.date_end
        today = getToday()
        date_start_year = event.date_start.getFullYear()
        date_start_month = event.date_start.getMonth()
        date_end_year = event.date_end.getFullYear()
        date_end_month = event.date_end.getMonth()
        n_months = ((date_end_year - date_start_year) * 12) + date_end_month - date_start_month + 1
        max_cols = 3;
        n_rows = Math.ceil(n_months / max_cols)
        n_cols = Math.min(max_cols, n_months)
        date_strings = event.event_dates['ALL'].map((event_date) -> event_date.date.toLocaleDateString("en-GB", {day: "numeric", month: "numeric", year: "numeric"}))
        $form.find('input[name="event_dates"]').val(date_strings.join(','))
        $calendar.multiDatesPicker({
          dateFormat: "d/m/yy",
          hideIfNoPrevNext: true,
          minDate: daysBetween(today, event.date_start),
          maxDate: daysBetween(today, event.date_end+1),
          addDates: if date_strings.length > 0 then date_strings else null,
          numberOfMonths: [n_rows,n_cols],
          onSelect: @updateSelectedCalendarDates
        })

  updateSelectedCalendarDates: (dateString) =>
    if $form = @getForm()
      $event_dates = $form.find('input[name="event_dates"]')
      $event_dates.val($form.find('#edit_event_calendar').multiDatesPicker('getDates').join(',')).keyup()

  #######################
  ##### Assignments #####
  #######################

  duplicateAssignments: ->
    if event = @db.findId('events', @getId())
      sourceTaxWeekId = getDropdownIntVal(@viewport.find('#assignments-tax-week-dropdown'))
      sourceDate = getDropdownDateVal(@viewport.find('#assignments-date-dropdown'))
      choices = []
      if sourceDate? or sourceTaxWeekId?
        if sourceDate?
          header = "Select Dates to Duplicate to"
          html = JST['office_views/_duplicate_assignments_daily']({header: header})
          bootbox.confirm({
            message: html,
            className: 'duplicate-assignments',
            callback:(result) =>
              if result
                targetDates = $('#duplicate-assignments-calendar').multiDatesPicker('getDates', 'object');
                @saveChanges('/office/duplicate_assignments_daily', {event_id: event.id, source_date: sourceDate, target_dates: targetDates}, NullActor, @db)
          }).init(=>
            $date_field = $('#duplicate-assignments-calendar')
            eventDates = event.event_dates['ALL'].filter((event_date) -> event_date.date.getTime() != sourceDate.getTime()).map((event_date) -> event_date.date)
            eventDatesAsGetTime = eventDates.map((date) -> date.getTime())
            allDates = getDatesFromRange(event.date_start, event.date_end)
            disabledDates = allDates.filter((date) -> ($.inArray(date.getTime(), eventDatesAsGetTime) == -1))
            $date_field.multiDatesPicker({minDate: event.date_start, maxDate: event.date_end, addDisabledDates: disabledDates})
          )
        else
          header = "Select Weeks to Duplicate to"
          for taxWeek in @db.queryAll('tax_weeks', {overlaps_dates: [event.date_start, event.date_end]}, 'date_start')
            unless taxWeek.id == sourceTaxWeekId
              choice = {}
              choice['value'] = taxWeek.id
              choice['label'] = printTaxWeek(taxWeek)
              choices.push(choice)
          html = JST['office_views/_duplicate_assignments_weekly']({header: header, choices: choices})
          bootbox.confirm({
            message: html,
            className: 'duplicate-assignments',
            callback:(result) =>
              if result
                targetTaxWeekIds = []
                $.each($("input[name='tax_week']:checked"), ->
                  targetTaxWeekIds.push($(this).val())
                )
                @saveChanges('/office/duplicate_assignments_weekly', {event_id: event.id, source_tax_week_id: sourceTaxWeekId, target_tax_week_ids: targetTaxWeekIds}, NullActor, @db)
          })
      else
        bootbox.alert("Must Select a Tax Week or Date")

  ###################
  ##### Clients #####
  ###################

  populateClientChoices: ($form, client_ids) =>
    client_ids ||= []
    active_clients = @db.queryAll('clients', {active: 'true'})
    active_client_ids = (client.id for client in active_clients)
    options = []
    $form ||= @getForm()

    for client in active_clients
      options.push {text: client.name, id: client.id}

    # We only show active clients in the dropdown. So make sure to add any inactive clients that are already
    # associated with this event
    for client_id in client_ids
      if client_id not in active_client_ids
        client = @db.findId('clients', client_id)
        options.push {text: client.name, id: client.id}

    options.sort (a, b) ->
      if a.text == b.text then 0 else if a.text < b.text then -1 else 1

    select2 = $form.find('select[name="event_clients[]"]')
    select2.html("")
    for option in options
      select2.append($('<option></option>').attr('value', option.id).html(option.text))
    select2.val(client_ids)
    select2.change()

  clientsBookingChangeHandler: (e) =>
    if $form = @getForm()
      client_ids = $($form.node('event_clients[]')).val()
      @populateCurrentClientChoices($form, client_ids)
      @updateClientFieldVisibility($form)

  updateClientFieldVisibility: ($form) ->
    client_ids = $form.node('event_clients[]').value
    booking_client_row = $($form.node('booking[client_id]')).closest('tr')
    if client_ids && client_ids.length > 1
      booking_client_row.show()
    else
      booking_client_row.hide()

  ##########################
  ##### Current Client #####
  ##########################

  populateCurrentClientChoices: ($form, client_ids) =>
    client_ids ||= []
    options = []
    $form ||= @getForm()
    for client_id in client_ids
      client = @db.findId('clients', client_id)
      options.push([client.name, client_id])
    options = options.sort (o1, o2) ->
      if o1[0] > o2[0] then 1 else if o1[0] < o2[0] then -1 else 0
    $current_client = $form.node('booking[client_id]')
    val = $current_client.value
    $current_client.innerHTML = buildOptions(options)
    if val and (val in client_ids)
      $current_client.value = val
    else
      $current_client.value = $current_client.options[0]?.value || ''
    $($current_client).change()

  currentClientChangeHandler: (e) =>
    #The following fields get pulled directly into email fields
    basic_booking_fields = ['dates', 'timings', 'crew_required', 'job_description', 'event_description', 'selling_points', 'staff_qualities', 'uniform', 'food', 'breaks', 'transport', 'meeting_location', 'rates', 'invoicing', 'timesheets', 'health_safety', 'any_other_information']
    #Add additional fields aren't used directly as email fields
    booking_fields = basic_booking_fields.concat ['wages', 'minimum_hours', 'office_notes', 'amendments', 'terms']
    booking_date_fields = ['date_sent', 'date_received']
    #All basic fields correspond directly to email fields, plus add additional fields that are calculated from other fields
    email_fields = ['contracted_by', 'event_display_name', 'event_address', 'booking_minimum_hours', 'booking_terms']
    email_fields = email_fields.concat(basic_booking_fields.map (field) -> "booking_"+field)
    #Fields that will get cleared on load
    clear_fields = ['health_safety_template']

    if $form  = @getForm()
      #If the client was manually changed, then e.originalEvent will be non-null, and we want to trigger a save
      if $form.node('booking[client_id]').value && e.originalEvent
        @saveAll({skip_refresh: true})
      @updateClientFieldVisibility($form)
      client_id = parseInt($form.node('booking[client_id]').value)
      if event = @db.findId('events', @getId())
        event_client = @db.queryAll('event_clients', {event_id: event.id, client_id: client_id})[0]
        if event_client
          booking = @db.queryAll('bookings', { event_client_id: event_client.id})[0]
          if booking
            @clearBookingFields($form, clear_fields, [])
            if booking.client_contact_id
              $($form.node('client_contact[id]')).val(booking.client_contact_id).change()
            for field in booking_fields
              $($form.node("booking[#{field}]")).val(booking[field] || '').change()
            for field in booking_date_fields
              fillDateInput($($form.node("booking[#{field}]")), booking[field]).change()
            client_contact_id = parseInt($form.node('client_contact[id]').value)
          else
            @clearBookingFields($form, booking_fields, email_fields)
        else
          @clearBookingFields($form, booking_fields, email_fields)
      else
        @clearBookingFields($form, booking_fields, email_fields)
      @populateClientContactChoices($form, client_id)

  ###########################
  ##### Client Contacts #####
  ###########################

  populateClientContactChoices: ($form, client_id) =>
    $form ||= @getForm()
    options = []
    $client_contact_select = $form.node('client_contact[id]')
    if client_id
      client_contacts = @db.queryAll('client_contacts', {client_id: client_id, active: true}, 'first_name')
      options.push(['', 0])
      for client_contact in client_contacts
        options.push(["#{client_contact.first_name} #{client_contact.last_name}", client_contact.id])
      options.push(["NEW", -1])

      if event = @db.findId('events', @getId())
        client_id = parseInt($form.node('booking[client_id]').value)
        event_client = @db.queryAll('event_clients', {event_id: event.id, client_id: client_id})[0]
        if event_client
          booking = @db.queryAll('bookings', { event_client_id: event_client.id})[0]
          if booking
            client_contact_id = booking.client_contact_id
    else
      options.push(['', '0'])
      $client_contact_select.innerHTML = ''
    $client_contact_select.innerHTML = buildOptions(options)
    $client_contact_select.value = client_contact_id if client_contact_id
    $($client_contact_select).change()

  clientContactChangeHandler: (e) =>
    if $form = @getForm()
      client_contact_id = parseInt($form.node('client_contact[id]').value)
      if client_contact_id <= 0
        for field in ['first_name', 'last_name', 'mobile_no', 'email']
          input = $form.node("client_contact[#{field}]")
          input.value = ''
          input.readOnly = false
        $form.find(".email_contracted_by").text('')
      else if client_contact = @db.findId('client_contacts', client_contact_id)
        for field in ['first_name', 'last_name', 'mobile_no', 'email']
          input = $form.node("client_contact[#{field}]")
          input.value = client_contact[field]
          input.readOnly = true
        client = @db.findId('clients', client_contact.client_id)
        $form.find(".email_contracted_by").text("#{client_contact.first_name} #{client_contact.last_name} on behalf of #{client.name}")

  populateLeaderClientContactChoices: ($form, client_ids, client_contact_id) =>
    $form ||= @getForm()
    options = [['',0]]
    $leader_client_contact_select = $form.find('select#event_leader_client_contact_id')
    for client_id in client_ids
      client_contacts = @db.queryAll('client_contacts', {client_id: client_id, active: true}, 'first_name')
      for client_contact in client_contacts
        options.push(["#{client_contact.first_name} #{client_contact.last_name}", client_contact.id])
    $leader_client_contact_select.html(buildOptions(options))
    $leader_client_contact_select.val(client_contact_id) if client_contact_id

  getForm: () ->
    if @newForm.active()
      @viewport.find('.record-new')
    else if @newBookingForm.active()
      @viewport.find('.record-new-booking')
    else if @editForm.active()
      @viewport.find('.record-edit')
    else
      null

  getId: () ->
    if @newForm.active()
      @newForm.editingId()
    else if @newBookingForm.active()
      @newBookingForm.editingId()
    else if @editForm.active()
      @editForm.editingId()
    else
      null

  clearBookingFields: ($form, booking_fields, email_fields) ->
    for field in booking_fields
      $form.node("booking[#{field}]").value = ''
    for field in email_fields
      $form.find(".email_#{field}").text('')
    $form.find('.viewBookingEmail').text('View Email Template ▼')
    $form.find('.booking-email-template').hide()

  viewBookingEmailTemplate: (e) =>
    $form = @getForm()
    template = $form.find('.booking-email-template')
    if $form.find('.booking-email-template').is(":visible")
      $form.find('.viewBookingEmail').text('View Email Template ▼')
      template.hide()
    else
      $form.find('.viewBookingEmail').text('View Email Template ▲')
      template.show()

  updateEmailField: (e) =>
    $form = @getForm()
    name = e.target.name.replace(/^([^\[]+)\[/, "$1_").replace(/\]/, "")
    if name == 'booking_minimum_hours'
      $form.find(".email_booking_minimum_hours").text(@getMinimumHoursString(e.target.value))
    else if name == 'booking_terms'
      $form.find(".email_booking_terms").text(@getTermsString(e.target.value))
    else
      $form.find(".email_#{name}").text(e.target.value || '')

  getMinimumHoursString: (min_hours) ->
    if min_hours && min_hours != ''
      if min_hours == 'Set'
        'Set daily charge rate per person per shift applies'
      else
        "Set #{min_hours} hourly minimum charge rate per person per shift applies"
    else
      ''

  getTermsString: (days) ->
    if days && days != ''
      "Payment due #{days} days from invoice date"
    else
      ''

  getHealthSafetyString: (type) ->
    if type == 'Outdoor Sport/Promotional'
      'Injury due to incorrect manual handling techniques, accidents from moving vehicles, environmental factors, such as sunburn, hyperthermia or dehydration or trips, slips & falls due to event infrastructure.'
    else if type == 'Outdoor Music/Hospitality'
      'Noise/hearing damage from music or PA systems, injury due to incorrect manual handling techniques or equipment use, accidents from moving vehicles, environmental factors, such as sunburn, hyperthermia, dehydration or fatigue, trips, slips & falls due to event infrastructure or dealing with audience behaviour.'
    else if type == 'Indoor Sport'
      'Injury due to incorrect manual handling techniques, dehydration or trips, slips & falls due to event infrastructure.'
    else if type == 'Indoor Music/Hospitality'
      'Noise/hearing damage from music or PA systems, injury due to incorrect manual handling techniques or equipment use, dehydration or fatigue, trips, slips & falls due to event infrastructure or dealing with audience behaviour.'
    else if type == 'Indoor Corporate/Promotional'
      'Injury due to incorrect manual handling techniques or equipment use, dehydration or fatigue, trips, slips & falls due to event infrastructure.'
    else
      ''

  bindClientHandlers: ($form) =>
    $form ||= @getForm()
    if $form
      rebind($($form.node('event_clients[]')), 'change', @clientsBookingChangeHandler)
      rebind($($form.node('booking[client_id]')), 'change', @currentClientChangeHandler)
      rebind($($form.node('client_contact[id]')), 'change', @clientContactChangeHandler)

  unbindClientHandlers: ($form) =>
    $form ||= @getForm()
    if $form
      $($form.node('event_clients[]')).unbind('change', @clientsBookingChangeHandler)
      $($form.node('booking[client_id]')).unbind('change', @currentClientChangeHandler)
      $($form.find('client_contact[id]')).unbind('change', @clientContactChangeHandler)

  getLeaderOptions: (eventId, type) =>
    users = []
    switch type
      when 'Prospect'
        gigs = @db.queryAll('gigs', {event_id: eventId})
        users = gigs.map (gig) -> @db.findId('prospects', gig.prospect_id)
      when 'ClientContact'
        event = @db.findId('events', eventId)
        for clientId in event.client_ids
          users = users.concat(@db.queryAll('client_contacts', {client_id: clientId}))
      when 'Officer'
        users = @db.queryAll('officers')
      when ''
        users = []
    users.sort(lastNameFirstNameSort).map (user) -> ["#{user.last_name}, #{user.first_name}", user.id]

  updateLeaderUserOptions: ($target, eventId, type) ->
    $target.html(buildOptions(@getLeaderOptions(eventId, type)))

  getActiveOperationalManagerOptions: (currentOfficerId = null) ->
    officers = @db.queryAll('officers', { active_operational_manager: true })
    if currentOfficerId
      currentOfficer = @db.findId('officers', currentOfficerId)
      officers.push(currentOfficer) unless currentOfficer in officers
    officers.sort(lastNameFirstNameSort).map((officer) -> [officer.first_name, officer.id])

  getSecondActiveOperationalManagerOptions: (currentOfficerId = null) ->
    officers = @db.queryAll('officers', { active_operational_manager: true })
    if currentOfficerId
      currentOfficer = @db.findId('officers', currentOfficerId)
      officers.push(currentOfficer) unless currentOfficer in officers
    officers.sort(lastNameFirstNameSort).map((officer) -> [officer.first_name, officer.id])

  getSeniorManagerOptions: (currentOfficerId = null) ->
    officers = @db.queryAll('officers', { senior_manager: true })
    if currentOfficerId
     currentOfficer = @db.findId('officers', currentOfficerId)
     officers.push(currentOfficer) unless currentOfficer in officers
    officers.sort(lastNameFirstNameSort).map((officer) -> [officer.first_name, officer.id])

window.EventsView = EventsView
