class GigsView extends View
  constructor: (@db, @viewport) ->
    super(@viewport)

    @title = 'Gigs'
    @shownSubview = 'hired'

    @commandBar = new CommandBar(@viewport.find('.command-bar'), @)
    @filterBar  = new FilterBar(@viewport.find('.filter-bar'), @)

    hiredColumns = [
      {name: 'Tax Week',             id: 'tax_week_id',             virtual: true, hidden: true}
      {name: 'Rmv',                                                                sortable: false},
      {name: 'Misc',                 id: 'miscellaneous_boolean'},
      {name: 'Conf',                 id: 'confirmed',               virtual: true, changes_with: ['confirmed', 'tax_week_id']},
      {name: 'Pub',                  id: 'published',                              changes_with: ['confirmed', 'published']},
      {name: 'Name',                 id: 'name',                                   changes_with: ['name', 'confirmed', 'miscellaneous_boolean']},
      {name: 'Main Job',             id: 'job_id'},
      {name: 'Main Work Area',        id: 'location_id'},
      {name: 'Filtered Assignments', id: 'filtered_assignment_ids', virtual: true, hidden: true},
      {name: 'Assignments',          id: 'assignment_ids',          virtual: true},
      {name: 'Tags',                 id: 'tag_ids',                 virtual: true, sort_by: (gig) => @db.findId('tags', gig.tag_id)?.name},
      {name: 'Notes',                id: 'notes'},
      {name: 'Email',                id: 'email',                   virtual: true, changes_with: ['email', 'tax_week_id']},
      {name: 'Tax',                  id: 'has_tax_choice',                         type: 'boolean'},
      {name: 'ID',                   id: 'has_identity',                           type: 'boolean'},
      {name: 'Miles'},
      {name: 'Live',                 id: 'status',                                 type: 'string'},
      {name: 'DBS',                  id: 'dbs_qualification_type',                 type: 'boolean'},
      {name: 'Age',                  id: 'age',                                    type: 'number'},
    ]

    @eventId = null
    @assignments = {all: []}
    @tags = []
    @assignmentDetailsWindow = null

    monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    hiredFormBuilder = (gig) =>
      name_classes = []
      currentTaxWeek = @getCurrentTaxWeekId()
      confirmed = currentTaxWeek && gig.tax_week[currentTaxWeek]?.confirmed == true
      if confirmed
        if gig.published
          name_classes.push("hilite-orange")
        else
          name_classes.push("hilite")
      else if gig.miscellaneous_boolean
        name_classes.push("hilite-green")
      name_classes.push("red-text") if gig.age && parseInt(gig.age) < 18

      ##### Basically a deep-copyish reconstruction of assignments out of the hash:
      if gig.job_id && gig.location_id
        assignment_ids = (assignment.id for assignment in @assignments.forJobAndLocation[gig.job_id][gig.location_id] || [])
      else if gig.job_id
        assignment_ids = (assignment.id for assignment in @assignments.forJob[gig.job_id] || [])
      else if gig.location_id
        assignment_ids = []

        for assignment in @assignments.all || []
          assignment_ids.push(assignment.id) if assignment.location_id == gig.location_id
      else
        assignment_ids = (assignment.id for assignment in @assignments.all || [])

      assignments = (@db.findId("assignments", assignment_id) for assignment_id in assignment_ids)

      ##### Make sure any selected assignments stay selected in the dropdown despite the job/location
      selected_assignments = (@db.findId('assignments', assignment_id) for assignment_id in gig.assignments['ALL'])
      filter = {}
      filter['tax_week_id'] = currentTaxWeek if currentTaxWeek
      selected_assignments = @db.filter('assignments', selected_assignments, filter)
      for assignment in selected_assignments
        assignments.unshift(assignment) unless assignment_ids.hasItem(assignment.id)

      prospect = @db.findId('prospects', gig.prospect_id)

      interviewRating = 0
      if prospect.flair_image != null
        interviewRating += prospect.flair_image
      if prospect.experienced != null
        interviewRating += prospect.experienced
      if prospect.chatty != null
        interviewRating += prospect.chatty
      if prospect.confident != null
        interviewRating += prospect.confident
      if prospect.language != null
        interviewRating += prospect.language

      flag = prospect.flag_photo
      if flag == null then flag = ""

      dist = 0
      event = @db.findId('events', gig.event_id)
      if (coord1 = coordinatesForRecord(prospect)) && (coord2 = coordinatesForRecord(event))
        dist = distanceBetweenPointsInMiles(coord1, coord2)

      @viewport.find('.filter-bar input[name="event_picker"]').val(event.name)
      @viewport.find('.applied-view .restricted-event').remove()
      @viewport.find('.hired-view .restricted-event').remove()
      if event?.is_restricted
        @viewport.find('.applied-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )
        @viewport.find('.hired-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )

      avg_rating = prospect.avg_rating
      if avg_rating == null
        avg_rating = 0
      location_ids = assignments.filter((assignment) -> assignment.job_id == gig.job_id ).map((assignment) -> assignment.location_id)
      location_ids = @db.queryAll('locations', {job_id: gig.job_id})
      locations = @locations.filter((location) -> location_ids.includes(location.id) )

#      my_assignments = @db.queryAll('assignments', {event_id: gig.event_id}).map((assignment) -> [assignment] )

#      v2_locations = @db.queryAll('jobs', {event_id: gig.event_id}).map((job) ->
#        @db.queryAll('assignments', {job_id: job.id}).map((assignment) ->
#          if gig.job_id
#            assignment.location_id if assignment.job_id == gig.job_id
#          else
#            assignment.location_id
#        )
#      )
#      debugger
#      v2_locations = [].concat.apply([], v2_locations);
#      debugger
#      v2_locations = @location.map((location) ->
#        debugger
#        [location.name, location.id]
#      )
#
#      if v2_locations.length > 0
#        v2_locations = v2_locations.filter((v, i, a) -> a.indexOf(v) == i)
#      my_locations = @db.findIds('locations', v2_locations)



      # Jobs
      v2_jobs = @jobs.map((job) ->
        if gig.location_id
#          check = @db.queryAll('assignments', {job_id: job.id}).map((assignment) ->
#            if assignment.location_id == gig.location_id
#              true
#            else
#              []
#          )
#          check = [].concat.apply([], check);
#
#          if check.length != 0
#            [job.name, job.id]
#          else if job.event_id == 3627
            [job.name, job.id]
        else
          [job.name, job.id]
      )
      v2_jobs_temp = v2_jobs
      v2_jobs = []
      for value, index in v2_jobs_temp
        if value != undefined
          v2_jobs.push(value)

      ["<input type='text' name='[gigs][" + gig.id + "][tax_week_id]' value='" + (currentTaxWeek || "") + "'>",
       "<input type='checkbox' class='fire-checkbox never-dirty' name='fire[]' value='" + gig.id + "'>",
       "<input type='checkbox' name='[gigs][" + gig.id + "][miscellaneous_boolean]'" + (if gig.miscellaneous_boolean then " checked='checked'" else "") + ">",
       "<input type='checkbox' name='[gigs][" + gig.id + "][confirmed]'" + (if confirmed then " checked='checked'" else "") + (if currentTaxWeek then '' else "disabled='disabled'" ) + ">",
       "<input type='checkbox' name='[gigs][" + gig.id + "][published]'" + (if gig.published then " checked='checked'" else "") + " readonly='' onclick='return false;'>",
       if name_classes.length > 0 then  "<img src='/prospect_photo/#{prospect.id}?force_refresh=#{Math.random()}' class='team_photo' >" + "<div><span class='" + name_classes.join(' ') + " gig-view-name-size'><b>"+prospectName(prospect)+"</b></span> <br> <small style='float: left;'> R: "+escapeHTML(avg_rating)+" </small> <small style='float: left; margin-left: 10px;'> #E:" +escapeHTML(prospect.n_gigs)+ " </small> " + flag + " </div>" else "<img src='/prospect_photo/#{prospect.id}?force_refresh=#{Math.random()}' class='team_photo' ><b class='gig-view-name-size'>" + prospectName(prospect) + "</b><br> <small  style='float: left;'> R: " +escapeHTML(avg_rating)+ "</small>" + "<small style='margin-left: 10px; float: left;'> #E:" +escapeHTML(prospect.n_gigs)+ " </small>" + flag ,
       buildSelect({name: '[gigs]['+gig.id+'][job_id]', options: [['','']].concat(v2_jobs), selected: gig.job_id, class: "jobs-dropdown"}),
       buildSelect({name: '[gigs]['+gig.id+'][location_id]', options: [['','']].concat(@locations.map((location) -> [location.name, location.id])), selected: gig.location_id, class: "locations-dropdown"}),
#       buildSelect({name: '[gigs]['+gig.id+'][location_id]', options: [['','']].concat(my_locations.map((location) -> [location.name, location.id])), selected: gig.location_id, class: "locations-dropdown"}),
#        buildSelect({name: '[gigs]['+gig.id+'][location_id]', options: [['','']].concat(v2_locations), selected: gig.location_id, class: "locations-dropdown"}),

      # The first (hidden) select is used to let the office controller know all the filtered assignments.
#        buildSelect({name: '[gigs][' + gig.id + '][all_filtered_assignment_ids][]', options: [['','']].concat(my_assignments), selected: assignments.map((assignment) -> assignment.id), class: "all-filtered-assignment-ids", multiple: true}),

        buildSelect({name: '[gigs][' + gig.id + '][all_filtered_assignment_ids][]', options: @getAssignmentOptions(assignments), selected: assignments.map((assignment) -> assignment.id), class: "all-filtered-assignment-ids", multiple: true}),
       # The second select is the actual filtered assignments chosen for this person
       [ buildSelect2({name: '[gigs][' + gig.id + '][assignment_ids][]', options: @getAssignmentOptions(assignments, gig.job_id, gig.location_id), selected: gig.assignments['ALL'], class: 'assignments-dropdown', multiple: true}),
         ($td) =>
           select2options = {
             width: "100%",
             closeOnSelect: false,
             containerCssClass: "assignments-dropdown-select2",
             templateSelection: (item) =>
               assignment = @db.findId('assignments', parseInt(item.id))
               #Remove the "open/total" text from the selection
               new_text = item.text.replace(/\s+[0-9]+\/[0-9]+$/, '').replace(/\s+[0-9]+✓$/, '')
               #If the person has not yet confirmed, show if any of their selected shifts are now full.
               if !confirmed && assignment.n_confirmed >= assignment.staff_needed
                  $('<span><img class="assignment-full-icon" src="Red_Light_Icon.svg"/>' + new_text + '</span>')
               else
                 new_text
             ,
             #Copy the original class to the new item
             templateResult: (item, container) =>
               if item.element
                 $(container).addClass($(item.element).attr("class"))
               item.text
           }
           $assignmentsDropdown = $td.find('select.assignments-dropdown')
           $assignmentsDropdown.select2(select2options)
           that = this
           $assignmentsDropdown.find(':selected').each(->
             assignmentClass = dayOfWeekClass(that.db.findId('shifts', that.db.findId('assignments', $(this).val()).shift_id).date)
             $(".assignments-dropdown-select2 .select2-selection__choice[title='#{escapeText($(this).text())}']").addClass(assignmentClass)
           )
       ],
       [ buildSelect2({name: '[gigs]['+gig.id+'][tag_ids][]', options: [['','']].concat(@tags.map((tag) -> [tag.name, tag.id])), selected: gig.tags, class: 'tags-dropdown', multiple: true}),
         ($td) =>
           $tagsDropdown = $td.find('select.tags-dropdown').select2({width: '100%', placeholder: ''})
           $td.find('.select2-container').addClass('tags-dropdown-container')
       ],
       [buildTextInput({name: "[gigs][" + gig.id + "][notes]", value: gig.notes}),
         ($td) =>
           $td.find('input').attr('title', gig.notes).tooltip('fixTitle') if gig.notes && gig.notes.length > 35
       ],
       if currentTaxWeek && gig.tax_week[currentTaxWeek]?.assignment_email_type
         template = @db.findId('assignment_email_templates', gig.tax_week[currentTaxWeek].assignment_email_template_id)
         type = switch gig.tax_week[currentTaxWeek].assignment_email_type
           when 'ShiftOffer' then 'Shift Offer'
           when 'CallToConfirm' then 'Call'
           when 'EmailToConfirm' then 'Email'
           when 'BookedOffer' then 'Booked Offer'
           else gig.tax_week[currentTaxWeek].assignment_email_type
         if template.name == 'Default' then type else type + ': ' + template.name
       else
         ''
       if prospect.status == 'EXTERNAL' then '' else (if gig.has_tax_choice then "\u2714" else "<span class='red-text'>\u2718</span>"),
       if prospect.status == 'EXTERNAL' then '' else (if gig.has_identity then "\u2714" else "<span class='red-text'>\u2718</span>"),

       "<div style='width: fit-content; margin: auto;'>" + dist + "</div>",
       buildSelect({name: '[gigs]['+gig.id+'][status]', options: [['Y','Active'],['N','Inactive']], selected: gig.status, class: "status-dropdown"}),
       if prospect.dbs_qualification == true && prospect.dbs_issue_date != null && prospect.dbs_issue_date >= getToday().setFullYear(getToday().getFullYear() - 2)
         switch gig.dbs_qualification_type
          when 'Basic' then 'B'
          when 'Enhanced' then 'EH'
          when 'Enhanced Barred List' then 'EH-B'
          else ''
       else
         ""
       gig.age
      ]
    @hiredView = new EditableStaticListView(@db, @viewport.find('.hired-view'), 'gigs', hiredColumns, hiredFormBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_gigs', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})
          ), @db)
      select: (data) =>
        if @editForm.in()
            prospect = @db.findId('prospects', data.record.prospect_id)
            @editRecord(prospect)
      activate: (data) =>
        if @editForm.in()
          @saveAndClose()
        else
          prospect = @db.findId('prospects', data.record.prospect_id)
          @editRecord(prospect)
      drew: =>
        @updateRowHandlers()
      clean: => @clean()
      dirty: => @dirty()),
      { saveOnChange: true})

    @hiredView.sortOnColumn('name', true)
    @hiredView.pageSize(16)

    appliedColumns = [
      {                           name: "Reject",       sortable: false},
      {                           name: "SpareFalse", hidden: true}
      {id:"spare",                name: "Spare"},
      {                           name: "Hire",         sortable: false},
      {id:"name",                 name:"Name"},
      {                           name:"Applied Job"},
      {id:'skills',               name:"Skills & Abilities"},
      {id:"prospect_character",   name:"Size"},
      {id: 'is_best',             name:"Best"},
      {id: 'notes',               name:"Notes"},
      {id: 'texted',              name:"TXT"},
      {id: 'email_status',        name:"E-M"},
      {id: 'left_voice_message',  name:"VM"},
      {name:"Distance"},
      {id:"no_show_contracts",    name:"NS"},
      {id:"cancelled_eighteen_hrs_contracts",       name:"CX-18"},
      {name:"Rating"},
      {id:"n_gigs",           name:"# Events",      type:"number"},
      {id:"age",              name:"Age",           type:"number"},
    ]
    appliedRowBuilder = (request) ->
      dist = 0
      prospect = window.db.findId('prospects', request.prospect_id)
      event = window.db.findId('events', request.event_id)
      if (coord1 = coordinatesForRecord(prospect)) && (coord2 = coordinatesForRecord(event))
        dist = distanceBetweenPointsInMiles(coord1, coord2)
      avg_rating = prospect.avg_rating
      if avg_rating == null
        avg_rating = 0
      flag = prospect.flag_photo
      if flag == null then flag = ""

      # job select options
      job_options = [['','']]
      jobs = window.db.queryAll('jobs', {event_id: event.id}).map((job) ->
        job_options.push([job.name, job.id])
      )
      # for job in jobs

      selected_job = ""
      if request.job_id
        job = window.db.findId('jobs', request.job_id)
#        job_options = [['',''], [job.name, job.id]]
        selected_job = request.job_id

      @viewport.find('.filter-bar input[name="event_picker"]').val(event.name)
      @viewport.find('.applied-view .restricted-event').remove()
      @viewport.find('.hired-view .restricted-event').remove()
      if event?.is_restricted
        @viewport.find('.applied-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )
        @viewport.find('.hired-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )

      ["<input type='checkbox' data-request-id='" + request.id + "' class='reject-checkbox big-box never-dirty' name='reject[]' value='" + request.id + "' />",
       # HTML does not serialize a checkbox that is false. Since this is the only component, then nothing will get serialized and we won't know the gig_request id.
       # First we define a hard-coded spare value of false
       "<input type='hidden' name='[gig_requests][" + request.id + "][spare]' value='false'>",
       # Then if the following 'real' checkbox is checked, it will override the previous 'false' value
       "<input type='checkbox' data-request-id='" + request.id + "' class='spare-checkbox big-box' name='[gig_requests][" + request.id + "][spare]' " + (if request.spare then 'checked' else '') + " />",
       "<input type='checkbox' data-request-id='" + request.id + "' class='hire-checkbox big-box never-dirty' name='hire[]' value='" + request.id + "'  />",
       (if (request.age? && (request.age < 18)) then "<img src='/prospect_photo/#{prospect.photo}' class='team_photo' >" + "<div><span class='red-text gig-view-name-size'><b>"+prospectName(prospect)+"</b></span> <br> <small style='float: left;'> R: "+escapeHTML(avg_rating)+" </small> <small style='float: left; margin-left: 10px;'> #E:" +escapeHTML(prospect.n_gigs)+ " </small> " + flag + " </div>" else "<img src='/prospect_photo/#{prospect.photo}' class='team_photo' ><b class='gig-view-name-size'>" + prospectName(prospect) + "</b><br> <small  style='float: left;'> R: " +escapeHTML(avg_rating)+ "</small>" + "<small style='margin-left: 10px; float: left;'> #E:" +escapeHTML(prospect.n_gigs)+ " </small>" + flag ),
       # first job select
       "<select class='form-control' name='[gig_requests][" + request.id + "][job_id]'>" + buildOptions(job_options, selected_job) + "</select>",
        request.skills,
       prospect.prospect_character,
        "<input type='checkbox' data-request-id='" + request.id + "' class='best-checkbox' name='[gig_requests][" + request.id + "][is_best]' " + (if request.is_best then 'checked' else '') + " />",
        [buildTextInput({name: "[gig_requests][" + request.id + "][notes]", value: request.notes}),
          ($td) =>
            $td.find('input').attr('title', request.notes).tooltip('fixTitle') if request.notes && request.notes.length > 35
        ],
       "<input type='checkbox' data-request-id='" + request.id + "' class='best-checkbox' name='[gig_requests][" + request.id + "][texted]' " + (if request.texted then 'checked' else '') + " />",
       "<input type='checkbox' data-request-id='" + request.id + "' class='best-checkbox' name='[gig_requests][" + request.id + "][email_status]' " + (if request.email_status then 'checked' else '') + " />",
       "<input type='checkbox' data-request-id='" + request.id + "' class='best-checkbox' name='[gig_requests][" + request.id + "][left_voice_message]' " + (if request.left_voice_message then 'checked' else '') + " />",
       dist,
       prospect.no_show_contracts,
       prospect.cancelled_eighteen_hrs_contracts,
       avg_rating,
       if request.n_gigs > 0 then request.n_gigs else "",
       request.age]
    @appliedView = new EditableStaticListView(@db, @viewport.find('.applied-view'), 'gig_requests', appliedColumns, appliedRowBuilder, Actor(
      save: (data) =>
        ServerProxy.saveChanges('/office/update_gig_requests', data.data, Actor(
          requestSuccess: (returned) ->
            data.actor.msg('saved', {sent: data.data, result: returned.result})
          requestError: (returned) ->
            data.actor.msg('notsaved', {sent: data.data, result: returned.result})
          requestFailure: ->
            data.actor.msg('notsaved', {sent: data.data})), @db)
      select: (data) =>
        if @editForm.in()
          prospect = @db.findId('prospects', data.record.prospect_id)
          @editRecord(prospect)
      activate: (data) =>
        if @editForm.in()
          @saveAndClose()
        else
          prospect = @db.findId('prospects', data.record.prospect_id)
          @editRecord(prospect)
      clean: => @clean()
      dirty: => @dirty()),
      { saveOnChange: true })
    @appliedView.sortOnColumn('name', true)
    @appliedView.setFilters({not_applicant: true, gig_id: null, ignored: false})

    enableHire = (requestId) =>
      @viewport.find('.applied-view .hire-checkbox[data-request-id=' + requestId + ']').prop('disabled', false)
      @viewport.find('.applied-view .reject-checkbox[data-request-id=' + requestId + ']').prop('disabled', false)
    disableHire = (requestId) =>
      @viewport.find('.applied-view .hire-checkbox[data-request-id=' + requestId + ']').prop('disabled', true).prop('checked', false)
      @viewport.find('.applied-view .reject-checkbox[data-request-id=' + requestId + ']').prop('disabled', true).prop('checked', false)

    $('a[href="#gigs"]').click =>
      event = window.db.findId('events', @eventId)
      @viewport.find('.applied-view .restricted-event').remove()
      @viewport.find('.hired-view .restricted-event').remove()
      if event?.is_restricted
        @viewport.find('.applied-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )
        @viewport.find('.hired-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )

    autosize(@viewport.find('.record-edit textarea'))
    @previousStatus = ''
    fillInEditForm = (form, record) =>
      TeamView::fillInEditForm.call(@, form, record)
      @viewport.find('#gig-prospect-profile').text('Loading...')
      $.ajax({url: '/office/fetch_profile/'+record.id, method: 'GET', dataType: 'html', cache: false})
        .done((html) => @viewport.find('#gig-prospect-profile').html(html))
      @viewport.find('#gigs-timesheet-notes').text('Loading...')
      $.ajax({url: '/office/fetch_timesheet_notes/'+record.id, method: 'GET', dataType: 'html', cache: false})
        .done((html) => @viewport.find('#gigs-timesheet-notes').html(html))
    @editForm = new RecordEditForm(@viewport.find('.record-edit'), @, fillInEditForm)
    @editForm = new SlidingForm(@editForm)
    TeamView::addStatusCallback.call(@)
    TeamView::addSendMarketingEmailCallback.call(@)

    @eventsList = TeamView::setupEventList.call(@, '#gig-prospect-events')
    @futureEventsList = TeamView::setupFutureEventList.call(@, '#gig-prospect-future-events')
    @requestList = TeamView::setupRequestList.call(@, '#gig-prospect-requests')
    @actionList = TeamView::setupActionList.call(@, '#gig-prospect-action-takens')

    @reportDownloader = new GigReportDownloader(@)
    @reportDialog = new GigReportDialog(@viewport.find('.report-download-dialog'), @reportDownloader)
    @reportMenu = new GigReportMenu(@, @viewport.find('.report-dropdown'), @reportDialog, @reportDownloader)

    @bulkSMSDialog = @viewport.find('.bulk-sms-dialog')

    @activeCheckbox = @viewport.find('.filter-bar input[name="active_only"]')
    @activeCheckbox.change(=> @setupEventPicker())

    @taxWeekDropdown = @viewport.find('.filter-bar select[name="tax_week_id"]')
    @taxWeekDropdown.change((e) => @taxWeekChanged(e.target))

    @asgnDateDropdown = @viewport.find('.filter-bar select[name="assignment_date"]')
    @appliedJobDropdown = @viewport.find('.filter-bar select[name="applied_job"]')
    @jobDropdown      = @viewport.find('.filter-bar select[name="job_id"]')
    @asgnDropdown     = @viewport.find('.filter-bar select[name="assignment_id"]')
    @locDropdown      = @viewport.find('.filter-bar select[name="location_id"]')
    @asgnJobDropdown  = @viewport.find('.filter-bar select[name="assignment_job_id"]')
    @asgnLocDropdown  = @viewport.find('.filter-bar select[name="assignment_location_id"]')
    @asgnShftDropdown = @viewport.find('.filter-bar select[name="assignment_shift_id"]')
    @tagDropdown      = @viewport.find('.filter-bar select[name="tag_id"]')
    @asgnTmplDropdown = @viewport.find('.filter-bar select[name="assignment_email_template_id"]')

    @asgnLocDropdown.change ->
      if window.db.queryAll('locations', {id: parseInt($(this).val(), 10)}).length > 0
        GigsView::updateAssignmentsFilter()

    @jobDropdown.change ->
      if window.db.queryAll('jobs', {id: parseInt($(this).val(), 10)}).length > 0
        GigsView::updateAssignmentsFilter()

    @locDropdown.change ->
      if window.db.queryAll('locations', {id: parseInt($(this).val(), 10)}).length > 0
        GigsView::updateAssignmentsFilter()

    @eventPicker = @viewport.find('.filter-bar input[name="event_picker"]')
    @eventPicker.keyup (e) ->
      if e.keyCode == 13 && $(this).val() == ''
        $('#gigs').find('.applied-view .restricted-event').remove()
        $('#gigs').find('.hired-view .restricted-event').remove()
      return
    @eventPicker.autocomplete({
      source: [],
      select: (e,ui) =>
        @eventPicker.val(ui.item.value)
        @filter({filters: @filterBar.selectedFilters()})
        events = @db.queryAll('events', {name: ui.item.value})
        @viewport.find('.hired-view .restricted-event').remove()
        @viewport.find('.applied-view .restricted-event').remove()
        if events[0]?.is_restricted
          @viewport.find('.hired-view').append(
            "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
          )
          @viewport.find('.applied-view').append(
            "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
          )
        dist_dropdown = @viewport.find('.filter-bar select[name="distance"]')
        dist_dropdown.empty()
        dist_dropdown.append(new Option('',''))
        event_id = events[0]?.id
        if event_id?
          for option in [['< 5', '0,5'],['< 10','0,10'],['< 20','0,20'],['< 30','0,30'],['< 40','0,40'],['< 50','0,50'],['5 - 10','5,10'],['10 - 20','10,20'],['20 - 30','20,30'],['30 - 40','30,40'],['40 - 50','40,50']]
            dist_dropdown.append(new Option(option[0], "#{event_id},#{option[1]}"))
    })
    @setupEventPicker()
    @filter({filters: @filterBar.selectedFilters()})

    @assignmentEmailDialog = @viewport.find('.assignment-email-dialog')
    @assignmentEmailDialog.modal({show: false})
    @assignmentEmailDialog.find('.close-btn').click(=> @assignmentEmailDialog.modal('hide'); @db.refreshData())
    @assignmentEmailDialog.find('.send-btn').click(=> @sendAssignmentEmails())
    @assignmentEmailDialog.find('#assignment_email_type, .custom-asgmt-email-field').on('change', => @saveAssignmentEmailTemplate(=> @previewAssignmentEmail()))
    @assignmentEmailDialog.find('#assignment_email_template').on('change', => @loadAssignmentEmailTemplate(); @previewAssignmentEmail())
    @assignmentEmailFields = ['office_message', 'arrival_time', 'meeting_location', 'meeting_location_coords', 'on_site_contact', 'contact_number', 'confirmation', 'uniform', 'welfare', 'transport', 'details', 'additional_info']

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

    @db.onUpdate('events', =>
      EventsView::updateStatistics()
      @setupEventPicker()
      @updateTaxWeekFilter())
    @db.onUpdate('gigs', (updateType) =>
      if @editForm.in()
        @eventsList.draw()
        @futureEventsList.draw()
        @viewport.find('.prospect-events-tab').text('Events (' + @eventsList.totalRecords() + ')')
        @viewport.find('.prospect-future-events-tab').text('Future Events (' + @futureEventsList.totalRecords() + ')')
      @updateSummary())
    @db.onUpdate('gig_requests', =>
      if @editForm.in()
        @requestList.draw()
        @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')'))
    @db.onUpdate('action_takens', =>
      if @editForm.in()
        @actionList.draw()
        @viewport.find('.prospect-action-taken-tab').text('Action Logs (' + @actionList.totalRecords() + ')'))
    @db.onUpdate('assignments', =>
      EventsView::updateStatistics()
      @updateAssignments())
    @db.onUpdate(['assignments', 'shifts', 'jobs', 'locations'], =>
      EventsView::updateStatistics()
      @updateAssignmentDetails())
    @db.onUpdate('tags', =>
      @tags =  @db.queryAll('tags', {event_id: @eventId}, 'name'))
    @db.onUpdate(['assignments', 'jobs', 'locations', 'shifts', 'tags'], =>
      EventsView::updateStatistics()
      assignmentId = @asgnDropdown.val()
      @updateAssignmentsFilter()
      if @asgnDropdown.val() != assignmentId
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('jobs', =>
      @jobs = @db.queryAll('jobs', {event_id: @eventId}, 'name')
      jobId = @asgnJobDropdown.val()
      @updateJobsFilter()
      if @asgnJobDropdown.val() != jobId
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('locations', =>
      @locations = @db.queryAll('locations', {event_id: @eventId}, 'name')
      locationId = @asgnLocDropdown.val()
      @updateLocationsFilter()
      if @asgnLocDropdown.val() != locationId
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('shifts', =>
      shiftId = @asgnShftDropdown.val()
      date = @asgnDateDropdown.val()
      @updateShiftsFilter()
      @updateDatesFilter()
      if @asgnShftDropdown.val() != shiftId || @asgnDateDropdown.val() != date
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('tags', =>
      tagId = @tagDropdown.val()
      @updateTagsFilter()
      if @tagDropdown.val() != tagId
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('assignment_email_templates', =>
      id = @asgnTmplDropdown.val()
      @updateAssignmentEmailTemplatesFilter()
      if @asgnTmplDropdown.val() != id
        @filter({filters: @filterBar.selectedFilters()}))
    @db.onUpdate('text_blocks', => @rebuildEmailTemplateDropdown())
    @db.onUpdate(['assignments', 'tags', 'gig_tax_weeks', 'gig_requests', 'gigs', 'gig_assignments'], (updateType) =>
      @draw())

    @rebuildEmailTemplateDropdown()

    @viewport.find('.applied-view, .applied-view-only').hide()
    @viewport.find('.hired-view, .hired-view-only').show()

    @viewport.find(".prospect_reject_photo").click(=> TeamView::rejectPhoto.call(@))

  ##### TeamView::fillInEditForm calls this routine, so we alias it
  populateCurrentClientChoices: (form, client_id) => TeamView::populateCurrentClientChoices.call(@, form, client_id)

  getCurrentTaxWeekId: ->
    val = @taxWeekDropdown.val()
    if val? && val != ''
      parseInt(val, 10)
    else
      null

  draw: ->
    if @shownSubview == 'hired'
      @hiredView.draw()
    else
      @appliedView.draw()

  saveHiredViewRow: (event) =>
    @hiredView.saveCurrentRow()

  saveAppliedViewRow: (event) =>
    @appliedView.saveCurrentRow()

  toggleSubview: ->
    if @shownSubview == 'hired'
      @viewport.find('.hired-view, .hired-view-only').hide()
      @viewport.find('.applied-view, .applied-view-only').show()
      @shownSubview = 'applied'
      @title = 'Gig Requests'
      @appliedView.draw()
      @clean()
    else
      @viewport.find('.applied-view, .applied-view-only').hide()
      @viewport.find('.hired-view, .hired-view-only').show()
      @shownSubview = 'hired'
      @title = 'Gigs'
      @hiredView.draw()
      if @hiredView.isDirty()
        @dirty()
      else
        @clean()
  revertGigs: ->
    if @editForm.in()
      @editForm.revert()
    else
      @hiredView.revert()

  removeProspects: ->
    if @eventId && (@db.findId('events', @eventId).status != 'CLOSED' || currentOfficerRole == 'manager' || currentOfficerRole == 'admin')
      gigIds = $.makeArray(@viewport.find('.fire-checkbox:checked')).map((check) -> $(check).attr('value'))
      if gigIds.length > 0
        fnRmv = (params) => ServerProxy.sendRequest('/office/delete_gigs', $.extend({ids: gigIds}, params), NotificationPopup, @db)
        showReasonDialog('Remove', fnRmv)

  deleteProspects: ->
    if @eventId && (@db.findId('events', @eventId).status != 'CLOSED' || currentOfficerRole == 'manager' || currentOfficerRole == 'admin')
      gigIds = $.makeArray(@viewport.find('.fire-checkbox:checked')).map((check) -> $(check).attr('value'))
      if gigIds.length > 0
        fnRmv = (params) => ServerProxy.sendRequest('/office/delete_gigs', $.extend({ids: gigIds, delete_gig_requests: true}, params), NotificationPopup, @db)
        showReasonDialog('Delete', fnRmv)

  hireProspects: ->
    requestIds = $.makeArray(@viewport.find('.hire-checkbox:checked')).map((check) -> $(check).attr('value'))
    eventOfficerID = @db.findId('events', @eventId)?.office_manager_id
    currentUserID = Number($('.officer_id').text())
    if requestIds.length > 0 && (eventOfficerID != currentUserID && @db.findId('events', @eventId)?.is_restricted == true) && @eventId && (@db.findId('events', @eventId).status != 'CLOSED' || currentOfficerRole == 'manager' || currentOfficerRole == 'admin')
      bootbox.confirm({
        message: "Candidate selection restricted. Speak to " + @db.findId('officers', eventOfficerID)?.first_name + " if your candidate is a knockout and should be considered.",
        buttons: {
          confirm: {
            label: 'Hire Agreed',
          }
        },
        callback:(result) ->
          if result == true
            ServerProxy.sendRequest('/office/create_gigs', {gig_requests: requestIds}, Actor(
              requestSuccess: (data) ->
                window.db.refreshData()), @db)
      })
    else
      if @eventId && (@db.findId('events', @eventId).status != 'CLOSED' || currentOfficerRole == 'manager' || currentOfficerRole == 'admin')
        if requestIds.length > 0
          ServerProxy.sendRequest('/office/create_gigs', {gig_requests: requestIds}, NotificationPopup, @db)

  rejectProspects: ->
    if @eventId && (@db.findId('events', @eventId).status != 'CLOSED' || currentOfficerRole == 'manager' || currentOfficerRole == 'admin')
      requestIds = $.makeArray(@viewport.find('.reject-checkbox:checked')).map((check) -> $(check).attr('value'))
      if requestIds.length > 0
        fnRmv = (params) => ServerProxy.sendRequest('/office/delete_gig_requests', $.extend({gig_requests: requestIds}, params), NotificationPopup, @db)
        showReasonDialog('Decline', fnRmv)

  clean: ->
    @commandBar.disableCommand('revert')
  dirty: ->
    @commandBar.enableCommand('revert')

  saveAndClose: ->
    if @editForm.in()
      @tryToSave(=>
        @editForm.stopEditing()
        if @shownSubview == 'hired'
          if @hiredView.isDirty()
            @dirty()
          else
            @clean()
        else
          @clean())

  close: ->
    @editForm.stopEditing()
    if @shownSubview == 'hired'
      if @hiredView.isDirty()
        @dirty()
      else
        @clean()
    else
      @clean()

  postSlideIn: ->
    if @editForm.in()
      autosize.update(@viewport.find('.record-edit textarea'))

  saveAll: ->
    @tryToSave(-> null)
  hide: (data) ->
    @tryToSave(-> data.actor.msg('hidden'))

  bulkSmsRegular: ->
    @bulkSMS(@getProspects(), 'Bulk SMS')
  bulkEmailRegular: ->
    @bulkEmail(@getProspects(), 'Bulk Email (All)')
  bulkEmailRegularGrouped: ->
    @bulkEmail(@getProspects(), 'Bulk Email (Groups of 400)', 400)
  bulkSmsMarketing: ->
    @bulkSMS((@getProspects().filter (p) -> (p.status == 'EMPLOYEE') && p.send_marketing_email), 'Bulk Marketing SMS (Employees Only)')
  bulkEmailMarketing: ->
    @bulkEmail((@getProspects().filter (p) -> (p.status == 'EMPLOYEE') && p.send_marketing_email), 'Bulk Marketing SMS (Employees Only - All)')
  bulkEmailMarketingGrouped: ->
    @bulkEmail((@getProspects().filter (p) -> (p.status == 'EMPLOYEE') && p.send_marketing_email), 'Bulk Marketing SMS (Employees Only - Groups of 400)', 400)

  getProspects: ->
    if @shownSubview == 'hired'
      @db.findIds('prospects', @hiredView.allRecords().map((g) -> g.prospect_id))
    else
      @db.findIds('prospects', @appliedView.allRecords().map((gr) -> gr.prospect_id))

  bulkSMS: (prospects, title) ->
    return if prospects.length == 0
    numbers = ""
    for prospect in prospects
      # If someone has indicated that they do not want to receive 'marketing e-mails', don't send SMS either
      if prospect.mobile_no?
        numbers = numbers.concat(prospect.mobile_no)
        numbers = numbers.concat('\n') unless prospect == prospects[prospects.length-1]
    @bulkSMSDialog.find('h3').text(title)
    @bulkSMSDialog.find('.content').empty()
    textarea = $("<textarea style='width:100%;height:200px'/>")
    textarea.text(numbers)
    @bulkSMSDialog.find('.content').append(textarea)
    @bulkSMSDialog.modal('show')

  bulkEmail: (prospects, title, maxPerGroup=99999999)->
    return if prospects.length == 0
    emails = ""
    i = 0
    while i < prospects.length
      prospect = prospects[i]
      # silly workaround for initially imported prospects with no email that were set to "...@nowhere.com"
      if prospect.email? && !(/@nowhere.com/g.exec(prospect.email))
        emails = emails.concat("#{prospect.first_name} #{prospect.last_name} <#{prospect.email}>")
        if i != prospects.length-1
          if i%(maxPerGroup-1) == 0 && i != 0
            emails = emails.concat("\n\n")
          else if i != prospects.length-1
            emails = emails.concat("; ")
      i += 1
    # we'll borrow the 'SMS numbers' dialog for this as well...
    @bulkSMSDialog.find('h3').text(title)
    @bulkSMSDialog.find('.content').empty()
    for string in emails.split("\n\n")
      textarea = $("<textarea style='width:100%;height:200px'/>")
      textarea.text(string)
      @bulkSMSDialog.find('.content').append(textarea)
    @bulkSMSDialog.modal('show')

  #############################
  ##### Assignment Emails #####
  #############################

  ##### TODO: save templates when generating preview

  createAssignmentEmailTemplate: =>
    bootbox.prompt("Enter New Template Name", (name) =>
      if name
        ServerProxy.saveChanges('/office/create_assignment_email_template', {event_id: @eventId, name: name}, Actor(
          requestSuccess: =>
            @previewAssignmentEmail(=>
              templateId = @db.queryAll('assignment_email_templates', {event_id: @eventId, name: name})[0].id
              @previewAssignmentEmail(=> @updateAssignmentEmailTemplateDropdown(templateId))
            )
        ), @db))

  duplicateAssignmentEmailTemplate: =>
    bootbox.prompt("Enter New Template Name (Copy of " + $('#assignment_email_template option:selected').text() + ")", (name) =>
      if name
        ServerProxy.saveChanges('/office/duplicate_assignment_email_template', {id: $('#assignment_email_template').val(), name: name}, Actor(
          requestSuccess: (data) =>
            @previewAssignmentEmail(=> @updateAssignmentEmailTemplateDropdown(data.result.new_id))
        ), @db))

  deleteAssignmentEmailTemplate: =>
    bootbox.confirm("Are you sure you want to delete '#{$('#assignment_email_template option:selected').text()}' template?", (deleteAssignment) =>
      if deleteAssignment
        ServerProxy.saveChanges('/office/delete_assignment_email_template', {id: $('#assignment_email_template').val()}, Actor(
          requestSuccess: =>
            defaultId = @db.queryAll('assignment_email_templates', {event_id: @eventId, name: 'Default'})[0].id
            $('#assignment_email_template').val(defaultId)
            @previewAssignmentEmail(=> @updateAssignmentEmailTemplateDropdown(defaultId))
        ), @db))

  updateAssignmentEmailTemplateDropdown: (templateId) =>
    templateOptions = @db.queryAll('assignment_email_templates', {event_id: @eventId}).map (template) -> [template.name, template.id]
    $('#assignment_email_template').html(buildOptions(templateOptions, templateId)).val(templateId)
    @loadAssignmentEmailTemplate(templateId)

  loadAssignmentEmailTemplate: (templateId=null) =>
    unless templateId
      templateId = $('#assignment_email_template').val()
    template = @db.findId('assignment_email_templates', templateId)
    for field in @assignmentEmailFields
      @assignmentEmailDialog.find('#'+field).val(template[field])

  showAssignmentEmailDialog: (cmdData) =>
    if taxWeekId = @getCurrentTaxWeekId()
      if gig = @hiredView.allRecords()[0]
        type = (gig.tax_week && gig.tax_week[taxWeekId] && gig.tax_week[taxWeekId].assignment_email_type) || 'Info'
        if gig.tax_week && gig.tax_week[taxWeekId] && gig.tax_week[taxWeekId].assignment_email_template_id
          templateId = gig.tax_week[taxWeekId].assignment_email_template_id
        else
          templateId = @db.queryAll('assignment_email_templates', {event_id: @eventId, name: 'Default'})[0].id
        @assignmentEmailDialog.find('#assignment_email_type').val(type)
        @updateAssignmentEmailTemplateDropdown(templateId)
        @previewAssignmentEmail(=>
          @assignmentEmailDialog.modal('show')
          autosize(@assignmentEmailDialog.find('textarea'))
        )
      else
        bootbox.alert('You Must Have At Least One Gig')
    else
      bootbox.alert('You Must Select a Week')

  saveAssignmentEmailTemplate: (callback=null) =>
    data = {templates: {}}
    templateId = $('#assignment_email_template').val()
    data['templates'][templateId]   = {}

    for field in @assignmentEmailFields
      data['templates'][templateId][field] = @assignmentEmailDialog.find('#'+field).val()

    ServerProxy.saveChanges('/office/update_assignment_email_templates', data, Actor(
      requestSuccess: =>
        callback() if callback
    ), @db)

  previewAssignmentEmail: (callback=null) ->
    gig_ids = @hiredView.allRecords().map((g) -> g.id)
    return if gig_ids.length == 0

    type = @assignmentEmailDialog.find('#assignment_email_type').val()
    template_id = @assignmentEmailDialog.find('#assignment_email_template').val()
    data = {gig_id: gig_ids[0], tax_week_id: @getCurrentTaxWeekId(), type: type, template_id: template_id}

    $.ajax(url: '/office/fetch_assignment_email_preview', data: data, dataType: 'html')
      .done((json) =>
        response = JSON.parse(json)

        $warning = $('<div>')
        if response.missing.length > 0
          $warning = $warning.append($('<strong>').text('Missing Information:'))
          $warning = $warning.append($('<div>').text(response.missing.join('\n')))
        if $warning.is(':empty')
          @assignmentEmailDialog.find('#assignment-email-warning').text('')
          @assignmentEmailDialog.find('.missing-only').hide()
        else
          @assignmentEmailDialog.find('#assignment-email-warning').empty().append($warning)
          @assignmentEmailDialog.find('.missing-only').show()

        @assignmentEmailDialog.find(".custom-asgmt-email-field.type-#{type}").show()
        @assignmentEmailDialog.find('.custom-asgmt-email-field').not(".type-#{type}").hide()
        autosize.update(@assignmentEmailDialog.find('textarea'))

        @assignmentEmailDialog.find('#assignment-email-subject').text(response.subject)
        @assignmentEmailDialog.find('#assignment-email-body').html(response.body)
        callback() if callback
  )

  sendAssignmentEmails: =>
    bootbox.confirm("Are you sure you want to send? Everything in the email you require?", (result) =>
      if result
        @assignmentEmailDialog.modal('hide')
        gig_ids = @hiredView.allRecords().map((g) -> g.id)
        return if gig_ids.length == 0

        type = @assignmentEmailDialog.find("#assignment_email_type").val()
        template_id = @assignmentEmailDialog.find('#assignment_email_template').val()
        data = {gig_ids: gig_ids, tax_week_id: @getCurrentTaxWeekId(), type: type, template_id: template_id}
        ServerProxy.saveChanges('/office/send_assignment_emails', data, Actor(
          requestSuccess: =>
            @db.refreshData()
        ), @db)
    )

  clearConfirmed: ->
    bootbox.confirm("Are you sure you want to clear the confirmed checkbox for all filtered gigs?", (result) =>
      if result
        ServerProxy.saveChanges('/office/clear_confirmed_on_gigs', {gig_ids: @hiredView.allRecords().map((gig) -> gig.id), tax_week_id: @getCurrentTaxWeekId() }, NullActor, @db))

  clearMisc: ->
    bootbox.confirm("Are you sure you want to clear the misc flags for all filtered gigs?", (result) =>
      if result
        ids = @hiredView.allRecords().map((gig) -> gig.id)
        ServerProxy.saveChanges('/office/clear_misc_flag', {ids: ids}, NullActor, @db))

  clearFilters: ->
    @viewport.find('.filter-bar').find('input[name="search"], select').val('')
    @viewport.find('.filter-bar select[name="status"]').val('Active')

  clearAndApplyFilters: ->
    @clearFilters()
    @filter({filters: @filterBar.selectedFilters()})
    @updateAssignmentsFilter()


  showRequestsForEvent: (data) ->
    @tryToSaveHiredView(=>
      @toggleSubview() if @shownSubview == 'hired'
      event = @db.findId('events', parseInt(data.event_id,10))
      @clearFilters()
      @viewport.find('.filter-bar select[name="spare"]').val(data.spare) if data.spare
      @eventPicker.val(event.name)
      @filter({filters: @filterBar.selectedFilters()}))

  showHiredForEvent: (data) ->
    @showHired(data)

  showAssignedForEvent: (data) ->
    @showHired(data, => @asgnDropdown.val(0))

  showHired: (data, fn=null) ->
    @tryToSaveHiredView(=>
      @toggleSubview() if @shownSubview != 'hired'
      event = @db.findId('events', parseInt(data.event_id,10))
      @clearFilters()
      @eventPicker.val(event.name)
      fn() if fn
      @filter({filters: @filterBar.selectedFilters()})
      # When filtering a new event, the tax week dropdown selects the default tax week
      # So we need to reset the taxWeekDropdown Value
      unless data.tax_week_id?
        if tax_week = getDefaultTaxWeekForEvent(event)
          data.tax_week_id ||= tax_week.id
      @taxWeekDropdown.val(data.tax_week_id).change())

  editRecord: (prospect) ->
    @tryToSave(=>
      @editForm.editRecord(prospect)
      @clean()
      @eventsList.setFilters({prospect_id: prospect.id, started_only: true})
      @futureEventsList.setFilters({prospect_id: prospect.id, future_only: true})
      @requestList.setFilters({prospect_id: prospect.id, future_only: true, gig_id: null})
      @actionList.setFilters({prospect_id: prospect.id})
      @eventsList.draw()
      @futureEventsList.draw()
      @requestList.draw()
      @actionList.draw()
      @viewport.find('.prospect-events-tab').text('Events (' + @eventsList.totalRecords() + ')')
      @viewport.find('.prospect-future-events-tab').text('Future Events (' + @futureEventsList.totalRecords() + ')')
      @viewport.find('.prospect-requests-tab').text('Gig Requests (' + @requestList.allRecords().length + ')')
      @viewport.find('.prospect-action-taken-tab').text('Action Logs (' + @actionList.totalRecords() + ')'))

  tryToSave: (callback) ->
    if @editForm.in() && @editForm.isDirty()
      @editForm.saveRecord('/office/update_prospect/', @db, Actor({saved: callback}), 'prospect')
    else
      callback()

  tryToSaveHiredView: (callback) ->
    if @hiredView.isDirty()
      @hiredView.save(Actor({saved: callback}))
    else
      callback()

  setupEventPicker: ->
    currentVal = @eventPicker.val()
    filter = {}
    filter = {active: true} if @activeCheckbox.prop('checked')
    events = @db.queryAll('events', filter, 'name')
    event_names = events.map((e) -> e.name)
    @eventPicker.autocomplete('option', 'source', event_names)
    if event_names.length == 0
      @eventPicker.val('')
    else if !event_names.hasItem(currentVal)
      @eventPicker.val(event_names[0])
      events = @db.queryAll('events', {name: event_names[0]})
      @viewport.find('.hired-view .restricted-event').remove()
      @viewport.find('.applied-view .restricted-event').remove()
      if events[0]?.is_restricted
        @viewport.find('.applied-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )
        @viewport.find('.hired-view').append(
          "<div style='float:right; margin-top: -22px; margin-right: 150px; background-color: darkorange; border: 2px solid black; border-radius: 13px;padding: 4px;' class='restricted-event'> <b> Restricted </b> </div>"
        )
      dist_dropdown = @viewport.find('.filter-bar select[name="distance"]')
      dist_dropdown.empty()
      dist_dropdown.append(new Option('',''))
      event_id = events[0]?.id
      if event_id?
        for option in [['< 5', '0,5'],['< 10','0,10'],['< 20','0,20'],['< 30','0,30'],['< 40','0,40'],['< 50','0,50'],['5 - 10','5,10'],['10 - 20','10,20'],['20 - 30','20,30'],['30 - 40','30,40'],['40 - 50','40,50']]
          dist_dropdown.append(new Option(option[0], "#{event_id},#{option[1]}"))

  getAssignmentOptions: (assignments, job_id, location_id) ->
    assignment_options = []
    for assignment in assignments
      if assignment.n_assigned > assignment.staff_needed
        assignment_options.push([printAssignmentWithStats(assignment, job_id, location_id), assignment.id, {class: 'assignment-overstaffed'}])
      else if assignment.n_assigned == assignment.staff_needed
        assignment_options.push([printAssignmentWithStats(assignment, job_id, location_id), assignment.id, {class: 'assignment-full'}])
      else
        assignment_options.push([printAssignmentWithStats(assignment, job_id, location_id), assignment.id, {class: 'assignment-open'}])
    assignment_options

  getGroupedAssignmentOptions: (assignments, job_id, location_id) ->
    assignment_options = []
    assignments_open = []
    assignments_full = []
    assignments_overstaffed = []
    for assignment in assignments
      if assignment.n_assigned > assignment.staff_needed
        assignments_overstaffed.push(assignment)
      else if assignment.n_assigned == assignment.staff_needed
        assignments_full.push(assignment)
      else
        assignments_open.push(assignment)

    assignment_options.push(['Open', assignments_open.map((assignment) -> [printAssignmentWithStats(assignment, job_id, location_id), assignment.id])]) if assignments_open.length > 0
    assignment_options.push(['Overstaffed', assignments_overstaffed.map((assignment) -> [printAssignmentWithStats(assignment, job_id, location_id), assignment.id])]) if assignments_overstaffed.length > 0
    assignment_options.push(['Full', assignments_full.map((assignment) -> [printAssignmentWithStats(assignment, job_id, location_id), assignment.id])]) if assignments_full.length > 0
    assignment_options

  updateTaxWeekFilter: (set_default_week) ->
    if @eventId?
      event = @db.findId('events', @eventId)
      tax_weeks = @db.queryAll('tax_weeks', {overlaps_dates: [event.date_start, event.date_end] })
      options = tax_weeks.map((tw) -> [printTaxWeek(tw), tw.id])
      selectedVal = @getCurrentTaxWeekId()
      if set_default_week
        if tax_week = getDefaultTaxWeekForEvent(event)
          selectedVal = tax_week.id
      @taxWeekDropdown.html(buildOptions([['', '']].concat(options), selectedVal))
      if selectedVal != @getCurrentTaxWeekId()
        @taxWeekChanged(@taxWeekDropdown)

  taxWeekChanged: (dropdown) ->
    # Clear email filter if no tax week selected
    if isNaN(parseInt($(dropdown).val(),10))
      @viewport.find('.filter-bar #email_sent').val('')
      @viewport.find('.filter-bar select[name="confirmed"]').val('')
      @viewport.find('.filter-bar .requires-tax-week').hide()
    else
      @viewport.find('.filter-bar .requires-tax-week').show()

  updateDatesFilter: ->
    if @eventId?
      options = EventsView::dateOptions.call(@, @eventId, getDropdownIntVal(@taxWeekDropdown))
      selectedVal = @asgnDateDropdown.val()
      @asgnDateDropdown.html(buildOptions([['', '']].concat(options), selectedVal))
      @updateAssignmentsFilter()

  updateAssignmentsFilter: ->
    if @eventId? || (@jobDropdown? || @asgnLocDropdown?)
      assignments = @assignments.all
      if @db.queryAll('locations', {id: parseInt(@asgnLocDropdown.val(), 10)}).length > 0
        assignments = @db.filter('assignments', assignments, {location_id: @asgnLocDropdown.val()})
      if @db.queryAll('jobs', {id: parseInt(@jobDropdown.val(), 10)}).length > 0
        assignments = @db.filter('assignments', assignments, {job_id: @jobDropdown.val()})

      date = @asgnDateDropdown.val()
      if isPresent(date)
        date = new Date(Date.parse(date))
        assignments = assignments.filter (assignment) ->
          @db.findId('shifts', assignment.shift_id).date.getTime() == date.getTime()
      options = @getGroupedAssignmentOptions(assignments)
      selectedVal = parseInt(@asgnDropdown.val(), 10)
      @asgnDropdown.html(buildOptions([['', ''],['None', -1],['Any',0]].concat(options), selectedVal))

  updateJobsFilter: ->
    if @eventId?
      jobs = @db.queryAll('jobs', {event_id: @eventId}, 'name')
      options = jobs.map((job) -> [job.name, job.id])
      selectedVal = parseInt(@asgnJobDropdown.val(), 10)
      @asgnJobDropdown.html(buildOptions([['', '']].concat(options), selectedVal))
      selectedVal = parseInt(@jobDropdown.val(), 10)
      @jobDropdown.html(buildOptions([['', ''],['None', -1]].concat(options), selectedVal))
      selectedVal = parseInt(@appliedJobDropdown.val(), 10)
      @appliedJobDropdown.html(buildOptions([['', '']].concat(options), selectedVal))

  updateLocationsFilter: ->
    if @eventId?
      locations = @db.queryAll('locations', { event_id: @eventId }, locationSort)
      options = locations.map((location) -> [printLocation(location), location.id])
      selectedVal = parseInt(@asgnLocDropdown.val(), 10)
      @asgnLocDropdown.html(buildOptions([['', '']].concat(options), selectedVal))
      selectedValloc = parseInt(@locDropdown.val(), 10)
      @locDropdown.html(buildOptions([['', ''], ['None', -1]].concat(options), selectedValloc))

  updateShiftsFilter: ->
    if @eventId?
      options = EventsView::shiftOptions.call(@, @eventId, getDropdownIntVal(@taxWeekDropdown), getDropdownDateVal(@asgnDateDropdown))
      selectedVal = parseInt(@asgnShftDropdown.val(), 10)
      @asgnShftDropdown.html(buildOptions([['', '']].concat(options), selectedVal))

  updateTagsFilter: ->
    if @eventId?
      tags = @db.queryAll('tags', {event_id: @eventId}, 'name')
      options = tags.map((tag) -> [tag.name, tag.id])
      selectedVal = parseInt(@tagDropdown.val(), 10)
      @tagDropdown.html(buildOptions([['', ''],['None', -1]].concat(options), selectedVal))

  updateAssignments: ->
    if @eventId?
      filter = {event_id: @eventId}

      val = @taxWeekDropdown.val()
      if val? && val != ''
        filter['tax_week_id'] = parseInt(val, 10)

      @assignments = {all: @db.queryAll('assignments', filter, assignmentSort), forJob: {}, forLocation: {}, forJobAndLocation: {}}

      jobs = @db.queryAll('jobs', {event_id: @eventId})

      for job in jobs
        filter['job_id'] = job.id
        @assignments.forJob[job.id] = @db.queryAll('assignments', filter, assignmentSort)
      filter['job_id'].delete if filter['job_id']

      locations = @db.queryAll('locations', {event_id: @eventId})
      for location in locations
        filter['location_id'] = location.id
        @assignments.forLocation[location.id] = @db.queryAll('assignments', filter, assignmentSort)
      filter['location_id'].delete if filter['location_id']

      for job in jobs
        filter['job_id'] = job.id
        for location in locations
          filter['location_id'] = location.id
          @assignments.forJobAndLocation[job.id] ||= {}
          @assignments.forJobAndLocation[job.id][location.id] = @db.queryAll('assignments', filter, assignmentSort)

  updateAssignmentEmailTemplatesFilter: ->
    if @eventId?
      templates = @db.queryAll('assignment_email_templates', {event_id: @eventId}, 'name')
      options = templates.map((template) -> [template.name, template.id])
      selectedVal = parseInt(@asgnTmplDropdown.val(), 10)
      @asgnTmplDropdown.html(buildOptions([['',''], ['None','None'], ['Any','Any']].concat(options), selectedVal))

  ############################
  ##### FilterBar Events #####
  ############################

  # Some filter contents depend on the settings of other filters
  # We use beforeFilter to adjust the filters contents before filtering
  beforeFilter: ->
    @updateAssignments()
    @updateDatesFilter()
    @updateAssignmentsFilter()
    @updateShiftsFilter()

  filter: (data) ->
    @tryToSaveHiredView(=>
      # fix up data passed in by filter bar
      delete data.filters.active_only

      ######################################
      ##### TAX WEEK DEPENDENT FILTERS #####
      ######################################
      if data.filters.tax_week_id? && data.filters.confirmed?
        data.filters.confirmed_for_tax_week = {}
        data.filters.confirmed_for_tax_week.tax_week_id = parseInt(data.filters.tax_week_id, 10)
        data.filters.confirmed_for_tax_week.value = (data.filters.confirmed == 'true')
      delete data.filters.confirmed

      delete data.filters.tax_week_id
      ######################################

      if (event_name = data.filters.event_picker)?
        events = @db.queryAll('events', {name: event_name})
        if events.length > 0
          data.filters.event_id = events[0].id
        delete data.filters.event_picker

      assignment_filter = {}
      assignment_filter['assignment_id'] = parseInt(data.filters.assignment_id, 10) if data.filters.assignment_id?
      assignment_filter['job_id']      = parseInt(data.filters.assignment_job_id, 10)          if data.filters.assignment_job_id?
      assignment_filter['location_id'] = parseInt(data.filters.assignment_location_id, 10)     if data.filters.assignment_location_id?
      assignment_filter['shift_id']    = parseInt(data.filters.assignment_shift_id, 10)        if data.filters.assignment_shift_id?
      assignment_filter['date']        = new Date(Date.parse(data.filters.assignment_date))    if data.filters.assignment_date?
      assignment_filter['all_filtered_assignment_ids'] = @assignments.all.map((assignment) -> assignment.id)
      data.filters.assignment = assignment_filter
      delete data.filters.assignment_id
      delete data.filters.assignment_job_id
      delete data.filters.assignment_location_id
      delete data.filters.assignment_shift_id
      delete data.filters.assignment_date

      data.filters.assignment_email_type = [@getCurrentTaxWeekId(), data.filters.assignment_email_type] if data.filters.assignment_email_type?
      data.filters.assignment_email_template_id = [@getCurrentTaxWeekId(), data.filters.assignment_email_template_id] if data.filters.assignment_email_template_id?

      data.filters.tag_id = parseInt(data.filters.tag_id, 10) if data.filters.tag_id?

      if !data.filters.event_id?
        @eventId = null
        @updateTaxWeekFilter(true)
        @assignments = {all: []}
        @tags = []
        @jobs = []
        @locations = []
        data.filters.event_id = -1 # non-existent ID -- make sure nothing passes the filter
        @jobDropdown.html('')
        @asgnDropdown.html('')
        @asgnJobDropdown.html('')
        @asgnLocDropdown.html('')
        @locDropdown.html('')
        @asgnShftDropdown.html('')
        @asgnDateDropdown.html('')
        @tagDropdown.html('')
        @viewport.find('.event-status').text('')
      else if @eventId != data.filters.event_id
        @eventId = data.filters.event_id
        @updateTaxWeekFilter(true)
        @jobs =  @db.queryAll('jobs', {event_id: @eventId}, 'name')
        @locations = @db.queryAll('locations', {event_id: @eventId}, 'name')
        @updateAssignments()
        @tags =  @db.queryAll('tags', {event_id: @eventId}, 'name')
        event = @db.findId('events', @eventId)
        @updateAssignmentsFilter()
        @updateJobsFilter()
        @updateLocationsFilter()
        @updateShiftsFilter()
        @updateDatesFilter()
        @updateTagsFilter()
        @updateAssignmentEmailTemplatesFilter()
        delete data.filters.assignment
        @viewport.find('.event-status').text(event?.status)

      # create a copy of "filters" object for applied view
      # if the hired and applied views share a "filters" object, it will cause problems when one or the other
      #   of them try to modify that object
      appliedFilters = deepCopy(data.filters)
      delete appliedFilters.job_id
      delete appliedFilters.location_id
      delete appliedFilters.assignment_id
      delete appliedFilters.assignment
      delete appliedFilters.tag_id
      delete appliedFilters.confirmed
      delete appliedFilters.published
      delete appliedFilters.has_ni
      delete appliedFilters.has_identity
      delete appliedFilters.email_sent
      delete appliedFilters.rating
      delete appliedFilters.has_tax_choice
      delete appliedFilters.has_bank_info
      delete appliedFilters.status
      delete appliedFilters.has_photo
      delete appliedFilters.miscellaneous_boolean
      appliedFilters.not_applicant = true
      appliedFilters.ignored = false
      appliedFilters.gig_id = null

      hiredFilters = deepCopy(data.filters)

      delete hiredFilters.spare

      @appliedView.setPage(1)
      @appliedView.setOffset(0)
      @appliedView.deselectRow()
      @appliedView.setFilters(appliedFilters)
      @appliedView.draw()

      @hiredView.setPage(1)
      @hiredView.setOffset(0)
      @hiredView.deselectRow()
      @hiredView.setFilters(hiredFilters)
      @hiredView.draw()
      @filterBar.refreshWidths()
      @updateSummary()
    )

  updateSummary: ->
    confirmed = 0
    assigned = 0
    needed = 0
    # Get all Assignments (based on current filters)
    # Determine the "needed" number from the assignments

    if @eventId
      filter = {event_id: @eventId}
      filter['tax_week_id']   = currentTaxWeek if currentTaxWeek = @getCurrentTaxWeekId()
      filter['id']            = id   if id   = getDropdownIntVal(@asgnDropdown)
      filter['job_id']        = id   if id   = getDropdownIntVal(@asgnJobDropdown)
      filter['location_id']   = id   if id   = getDropdownIntVal(@asgnLocDropdown)
      filter['shift_id']      = id   if id   = getDropdownIntVal(@asgnShftDropdown)
      filter['date']          = date if date = getDropdownDateVal(@asgnDateDropdown)

      assignments = @db.queryAll('assignments', filter)
      for assignment in assignments
        needed   += assignment.staff_needed
        assigned += assignment.n_assigned
        confirmed += assignment.n_confirmed

    @viewport.find('#value-confirmed').text(confirmed)
    @viewport.find('#value-assigned').text(assigned)
    @viewport.find('#value-needed').text(needed)

  assignmentDetailsWindowOpen: =>
    @assignmentDetailsWindow? && !@assignmentDetailsWindow.closed

  openAssignmentDetailsWindow: =>
    if @getCurrentTaxWeekId()
      new_window = false
      unless @assignmentDetailsWindowOpen()
        new_window = true
        @assignmentDetailsWindow = window.open('/office/assignment_details', 'Assignment Details', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,width=100,height=100')
      if typeof(@assignmentDetailsWindow) == 'undefined'
        bootbox.alert("You must unblock popups in order to see assignment details")
      else
        if new_window
          @assignmentDetailsWindow.window.onload = =>
            @updateAssignmentDetails()
            @assignmentDetailsWindow.focus()
        else
          @updateAssignmentDetails()
          @assignmentDetailsWindow.focus()
    else
      bootbox.alert('You must choose a tax week in order to see assignment details')

  updateAssignmentDetails: ->
    if @assignmentDetailsWindowOpen()
      data = {}
      data['dates'] = []
      if date = getDropdownDateVal(@asgnDateDropdown)
        data['dates'].push(date)
      else if currentTaxWeekId = @getCurrentTaxWeekId()
        shifts = @db.queryAll('shifts', {event_id: @eventId, tax_week_id: currentTaxWeekId})
        data['dates'] = (shift.date for shift in shifts).uniqueItems().sort((a,b) -> a.getTime() - b.getTime())

      assignments = @db.queryAll('assignments', {event_id: @eventId})

      data['jobs'] = {}
      data['locations'] = {}
      data['shifts'] = {}
      data['stats'] = {}
      data['total_stats'] = {}
      for date in data['dates']
        data['jobs'][date] = {}
        data['locations'][date] = {}
        data['shifts'][date] = {}
        data['stats'][date] = {}
        data['total_stats'][date] = {}

        data['total_stats'][date]['confirmed'] = 0
        data['total_stats'][date]['assigned'] = 0
        data['total_stats'][date]['needed'] = 0

        for a in @db.queryAll('assignments', {event_id: @eventId, date: date})
          # Store in hash to weed out duplicates
          data['jobs'][date][a.job_id] = @db.findId('jobs', a.job_id)
          data['locations'][date][a.location_id] = @db.findId('locations', a.location_id)
          data['shifts'][date][a.location_id] ||= {}
          data['shifts'][date][a.location_id][a.shift_id] = @db.findId('shifts', a.shift_id)

          data['stats'][date][a.location_id] ||= {}
          data['stats'][date][a.location_id][a.shift_id] ||= {}
          data['stats'][date][a.location_id][a.shift_id][a.job_id] ||= {}
          data['stats'][date][a.location_id][a.shift_id][a.job_id]['confirmed'] = a.n_confirmed
          data['stats'][date][a.location_id][a.shift_id][a.job_id]['assigned'] = a.n_assigned
          data['stats'][date][a.location_id][a.shift_id][a.job_id]['needed'] = a.staff_needed
          data['total_stats'][date]['confirmed'] += a.n_confirmed
          data['total_stats'][date]['assigned'] += a.n_assigned
          data['total_stats'][date]['needed'] += a.staff_needed

        # Convert hashes to sorted Arrays
        data['jobs'][date]      = Object.keys(     data['jobs'][date]).map((key) ->      data['jobs'][date][key]).sort()
        data['locations'][date] = Object.keys(data['locations'][date]).map((key) -> data['locations'][date][key]).sort(locationByEarliestShiftSort)
        for location_id, shifts of data['shifts'][date]
          data['shifts'][date][location_id] = Object.keys(shifts).map((key) -> data['shifts'][date][location_id][key]).sort(shiftSort)

      if data['dates']
        html = JST['office_views/_assignment_details'](data)
        assignmentDetailsDiv = @assignmentDetailsWindow.document.getElementById('assignment-details')
        assignmentDetailsDiv.innerHTML = html
        info = assignmentDetailsDiv.getBoundingClientRect()
        @assignmentDetailsWindow.resizeTo(info.right, info.bottom+50)

  rebuildEmailTemplateDropdown: ->
    dropdown = @viewport.find('.email-dropdown')
    dropdown.empty()

    @db.queryAll('text_blocks', {type: 'email'}, 'key').forEach((block) =>
      option = $('<li><a href="#">' + escapeHTML(block.key) + '</a></li>')
      option.click(=>
        @subview = if @shownSubview == 'hired' then @hiredView else @appliedView
        if @editForm.in()
          sendEmail(block, [@db.findId('prospects', @subview.selectedRecord().prospect_id)])
        else
          sendEmail(block, @db.findIds('prospects', @subview.allRecords().map((g) -> g.prospect_id))))
      dropdown.append(option))

  numRowsApplied: (numRows) =>
#    @appliedView.pageSize(numRows)
#    @appliedView.draw()

  numRowsHired: (numRows) =>
#    @hiredView.pageSize(numRows)
#    @hiredView.draw()

  removeUnconfirmedGigs: =>
    bootbox.confirm("Are you sure you want to remove all unconfirmed gigs?", (result) =>
      if result
        ServerProxy.saveChanges('/office/remove_unconfirmed_gigs', {gig_ids: @hiredView.allRecords().map((g) -> g.id), event_id: @eventId, gig_type: @shownSubview, tax_week_id: @getCurrentTaxWeekId() }, NotificationPopup, @db)
    )

  updateRowHandlers: =>
    ##### If a select2 was open when a select2 gets destroyed (ie. when another row is saved), then it will stay open on
    ##### the screen permanently. So we will delete them as they are no longer connected to anything.
    $('.select2-container--open').each (i, obj) ->
      if id = $(obj).find('.select2-results__options[role="tree"]').prop('id')
        if $('[aria-owns="'+ id + '"]').length == 0
          $(obj).remove()

  downloadEtihadPackage: =>
    ##### One time download for a set of events. YUCK!
    $.fileDownload("/office/download_etihad_package",
      httpMethod: 'POST',
      data: {
        event_id: @eventId,
      },
      failCallback: ->
        alert("Sorry, a server error occurred and the file could not be downloaded. Please report this to the application developers."))

  downloadAccreditation: =>
    gig_ids = @hiredView.allRecords().map((g) -> g.id)
    return if gig_ids.length == 0
    $.fileDownload("/office/download_accreditation",
      httpMethod: 'POST',
      data: {
        event_id: @eventId,
        gig_ids: gig_ids
      },
      failCallback: ->
        alert("Sorry, a server error occurred and the file could not be downloaded. Please report this to the application developers."))

  downloadWebAppData: =>
    # For some reason refreshData doesn't like to trigger via the callback.
    $.fileDownload("/office/download_webapp_data",
      httpMethod: 'POST',
      data: { event_id: @eventId },
      abortCallback: ->
        window.db.refreshData()
      prepareCallback: ->
        window.db.refreshData()
      successCallback: ->
        window.db.refreshData()
      failCallback: ->
        window.db.refreshData()
        alert("Sorry, a server error occurred and the file could not be downloaded. Please report this to the application developers."))
    window.db.refreshData()

  downloadDbsReport: =>
    # For some reason refreshData doesn't like to trigger via the callback.
    $.fileDownload("/office/download_dbs_data",
      httpMethod: 'POST',
      data: { event_id: @eventId },
      abortCallback: ->
        window.db.refreshData()
      prepareCallback: ->
        window.db.refreshData()
      successCallback: ->
        window.db.refreshData()
      failCallback: ->
        window.db.refreshData()
        alert("Sorry, a server error occurred and the file could not be downloaded. Please report this to the application developers."))
    window.db.refreshData()

class GigReportDownloader
  constructor: (@gigsView) ->

  records: (table) ->
    if @gigsView.shownSubview == 'hired'
      if table == 'gigs'
        @gigsView.hiredView.allRecords()
      else if table == 'gig_assignments'
        records = []
        for gig in @gigsView.hiredView.allRecords()
          filter = {gig_id: gig.id}
          if currentTaxWeek = @gigsView.getCurrentTaxWeekId()
            filter['tax_week_id'] = currentTaxWeek
          records = records.concat(@gigsView.db.queryAll('gig_assignments', filter, gigAssignmentSort))
        records
      else if table == 'assignments'
        @gigsView.db.queryAll('assignments', {event_id: @gigsView.eventId}, assignmentSort)
      else
        alert 'Unknown Table'
    else
      @gigsView.appliedView.allRecords()

  okForDownload: (tableName) ->
    records = @records(tableName)
    if records.length > 1000
      alert("Sorry, you can't generate a report for more than 1000 records at once. (Right now, " + records.length + " are selected.)")
      false
    else if records.length == 0
      alert("No records are selected for inclusion in the report.")
      false
    else
      true

  download: (reportName, tableName, format, dialog) ->
    if @okForDownload(tableName)
      downloadIt = =>
        records = @records(tableName)
        ids = records.map((r) -> r.id)
        $.fileDownload('/office/download_report', {
          httpMethod: 'POST',
          data: {format: format, ids: ids.join(','), report: reportName},
          successCallback: ->
            dialog.modal('hide')
          failCallback: ->
            alert("Sorry, a server error occurred and the report could not be downloaded.")
            dialog.modal('hide')
        })
      if @shownSubview == 'hired'
        # To make sure that data downloaded in report matches what user sees in their view,
        # save the most recent edits before asking the server to generate the report
        @hiredView.save(Actor({saved: downloadIt}))
      else
        downloadIt()

class GigReportMenu
  constructor: (@gigsView, @dropdownMenu, @dialog, @downloader) ->
    @dropdownMenu.on('click', 'a', (event) =>
      if (type = $(event.target).attr('data-report-event-type'))
        if @downloader.okForDownload('gigs')
          date = getDropdownDateVal(@gigsView.asgnDateDropdown)
          if type == 'large' && !(date?)
            bootbox.alert("You Must Set the Date Filter for a Large Event Report")
          else if type == 'medium' && date?
            bootbox.alert("You Cannot Set the Date Filter for a Medium Event Report")
          else
            gig_ids = @downloader.records('gigs').map((r) -> r.id)
            gig_assignment_ids = @downloader.records('gig_assignments').map((r) -> r.id)
            page_breaks = $(event.target).attr('data-with-page-breaks')
            @gigsView.hiredView.save(Actor({
              saved: =>
                $.fileDownload('/office/download_custom_gig_report', {
                  httpMethod: 'POST',
                  data: {gig_ids: gig_ids.join(','), gig_assignment_ids: gig_assignment_ids.join(','), type: type, page_breaks: page_breaks, event_id: @gigsView.eventId, tax_week_id: @gigsView.getCurrentTaxWeekId(), date: printDate(date)},
                  failCallback: ->
                    alert("Sorry, a server error occurred and the report could not be downloaded.")
                })
            }))
      else if $(event.target).attr('data-report-reg-sheet-with-blanks')?
        if @downloader.okForDownload('gigs')
          gig_ids = @downloader.records('gigs').map((r) -> r.id)
          gig_assignment_ids = @downloader.records('gig_assignments').map((r) -> r.id)
          @gigsView.hiredView.save(Actor({
            saved: =>
              $.fileDownload('/office/download_custom_registration_sheet', {
                httpMethod: 'POST',
                data: {gig_ids: gig_ids.join(','), gig_assignment_ids: gig_assignment_ids.join(','), event_id: @gigsView.eventId, tax_week_id: @gigsView.getCurrentTaxWeekId(), date: printDate(date)},
                failCallback: ->
                  alert("Sorry, a server error occurred and the report could not be downloaded.")
              })
          }))
      else if $(event.target).attr('data-report-reg-sheet-with-blanks-daily')?
        if @downloader.okForDownload('gigs')
          gig_ids = @downloader.records('gigs').map((r) -> r.id)
          gig_assignment_ids = @downloader.records('gig_assignments').map((r) -> r.id)
          @gigsView.hiredView.save(Actor({
            saved: =>
              $.fileDownload('/office/download_custom_registration_sheet_daily', {
                httpMethod: 'POST',
                data: {gig_ids: gig_ids.join(','), gig_assignment_ids: gig_assignment_ids.join(','), event_id: @gigsView.eventId, tax_week_id: @gigsView.getCurrentTaxWeekId(), date: printDate(date)},
                failCallback: ->
                  alert("Sorry, a server error occurred and the report could not be downloaded.")
              })
          }))
      else
        reportName = $(event.target).attr('data-report-name')
        tableName = $(event.target).attr('data-report-table')
        if @downloader.okForDownload(tableName)
          @dialog.open(reportName, tableName))

class GigReportDialog
  constructor: (@viewport, @downloader) ->
    @viewport.modal({show: false})
    @viewport.find('a.download-xlsx').click(=>
      @downloader.download(@selectedReport, @selectedTable, 'xlsx', @viewport))
    @viewport.find('a.download-csv').click(=>
      @downloader.download(@selectedReport, @selectedTable, 'csv', @viewport))
    @viewport.find('a.download-pdf').click(=>
      @downloader.download(@selectedReport, @selectedTable, 'pdf', @viewport))

  open: (reportName, tableName) ->
    @selectedReport = reportName
    @selectedTable = tableName
    @viewport.modal('show')

window.GigsView = GigsView
