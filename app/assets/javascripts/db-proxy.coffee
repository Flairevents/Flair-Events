# A client-side proxy for the DB which resides on the server
# Loads and caches all the needed data from the server, then updates it periodically
# Besides storing the data (in memory) and supplying it to the Views, can also filter/sort/search/offset/limit results

class DbProxy
  constructor: (@dataUrl, @loadingIndicator) ->
    @Index = 0
    now = new Date
    lastSixthStart = new Date 1900+now.getYear(), now.getMonth()-6, 1
    lastMonthEnd = new Date 1900+now.getYear(), now.getMonth(), 0
    getDates = (startDate, stopDate) ->
      dateArray = []
      currentDate = moment(startDate)
      stopDate = moment(stopDate)
      while currentDate <= stopDate
        dateArray.push moment(currentDate).format('YYYY-MM-DD')
        currentDate = moment(currentDate).add(1, 'days')
      dateArray
    @lastSixMonthDates = getDates(lastSixthStart, lastMonthEnd)
    @GRIndex = 0
    @tables = {}
    @associations = {}
    @filterFunctions = {}
    # to speed up queries:
    @indexes = {} # {table_name: {column_name: {value: [records]}}}

    @nowRefreshing = false
    @lastRefreshed = null
    @timeoutIDs = []

    # for updating GUI displays:
    @refreshCallbacks = [] # [{tables: tables, callback: callback}... ]

    @associationConfig = []
    @associationType = {}
    @associationJoinTableName = {}

    @addAssociation({type: 'ManyToMany', table1: 'bulk_interviews', table2: 'events'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'assignments'})
    @addAssociation({type: 'ManyToMany', table1: 'events',          table2: 'clients'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'event_clients'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'event_dates'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'event_tasks'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'expenses'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'gigs'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'gig_requests'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'pay_weeks'})
    @addAssociation({type: 'OneToOne',   table1: 'event_clients',   table2: 'bookings'})
    @addAssociation({type: 'OneToOne',   table1: 'event_clients',   table2: 'invoices'})
    @addAssociation({type: 'ManyToMany', table1: 'gigs',            table2: 'assignments'})
    @addAssociation({type: 'OneToMany',  table1: 'gigs',            table2: 'gig_tax_weeks'})
    @addAssociation({type: 'ManyToMany', table1: 'gigs',            table2: 'tags'})
    @addAssociation({type: 'OneToMany',  table1: 'jobs',            table2: 'gigs'})
    @addAssociation({type: 'ManyToMany', table1: 'locations',       table2: 'shifts',      joinTable: 'assignments'})
    @addAssociation({type: 'OneToOne',   table1: 'officers',        table2: 'accounts',    idName1: 'user_id'})
    @addAssociation({type: 'OneToMany',  table1: 'officers',        table2: 'event_tasks'})
    @addAssociation({type: 'OneToMany',  table1: 'prospects',       table2: 'gigs'})
    @addAssociation({type: 'OneToMany',  table1: 'prospects',       table2: 'gig_requests'})
    @addAssociation({type: 'OneToOne',   table1: 'prospects',       table2: 'interviews'})
    @addAssociation({type: 'OneToOne',   table1: 'events',          table2: 'event_sizes'})
    @addAssociation({type: 'OneToMany',  table1: 'shifts',          table2: 'assignments'})
    @addAssociation({type: 'OneToMany',  table1: 'tax_weeks',       table2: 'event_dates'})
    @addAssociation({type: 'OneToMany',  table1: 'tax_weeks',       table2: 'pay_weeks'})
    @addAssociation({type: 'OneToMany',  table1: 'tax_years',       table2: 'tax_weeks'})
    @addAssociation({type: 'OneToMany',  table1: 'regions',         table2: 'prospects'})
    @addAssociation({type: 'OneToMany',  table1: 'prospects',       table2: 'action_takens'})
    @addAssociation({type: 'OneToMany',  table1: 'events',          table2: 'action_takens'})
    @addAssociation({type: 'OneToOne',   table1: 'prospects',       table2: 'questionnaires'})

    @initializeFilters()
    @loadingIndicator.fadeIn()
    @refreshData('load')

  refreshData: (updateType='refresh') =>
    return if @nowRefreshing

    @nowRefreshing = true
    SavingChangesSpinner.startRequest('db-refresh') # arbitrary ID string

    $.ajax({url: @dataUrl, method: 'GET', data: {last: @lastRefreshed}, dataType: 'json', cache: false})
      .done((data) =>
        if data.status == 'error' && data.message?
          NotificationPopup.requestError({result: data})
        else
          # Since we also refresh manually, clear any scheduled timeouts before setting the next
          while @timeoutIDs.length > 0
            clearTimeout(@timeoutIDs.pop())
          # Schedule another refresh in 3 mins
          @timeoutIDs.push(setTimeout((=> @refreshData('refresh')), 3*60*1000))
        @updateData(data, updateType)
        @lastRefreshed = data.timestamp
        @nowRefreshing = false
        SavingChangesSpinner.requestFinished('db-refresh')
        @loadingIndicator.fadeOut())
      .fail((xhr, status, error) =>
        console.error('AJAX request for data failed')
        console.error(xhr)
        console.error(status)
        console.error(error)
        @nowRefreshing = false
        SavingChangesSpinner.requestFinished('db-refresh')
        @loadingIndicator.fadeOut()
        alert("An error occurred when trying to load data from the server. If you refresh the page, and this happens again, please contact the developers at error@appybara.com."))

  updateData: (data, updateType) =>
    @changed = {}
    @recordsToDelete = {}
    today = getToday()
    last_week = getToday()
    last_week.setDate(last_week.getDate()-7)
    last_week.setHours(0,0,0,0)

    ################################
    ##### Preprocess Deletions #####
    ################################
    # Only delete if record actually exists
    # Clear the indexes so that they will be regenerated *without* the record to be deleted
    @recordsToDelete = {}
    if data.deleted
      for tableName,record_ids of data.deleted when record_ids.length > 0
        for id in record_ids
          (@recordsToDelete[tableName] ||= []).push(id) if @findId(tableName, id)
        @indexes[tableName] = {} if @recordsToDelete[tableName]?.length > 0

    #########################
    ##### Import Tables #####
    #########################
    importTableStart = new Date

    if data.tables
      importTables(data.tables, (tableName, records) =>
        if records.length > 0
          @changed[tableName] = records
          @deleteStaleAssociations()
          @updateTable(tableName, records)
        else
          @tables[tableName] ||= {})

    if data.todos && Object.keys(data.todos).length > 0
      @tables.todos ||= {}
      @changed.todos ||= []
      for id, todo of data.todos
        @tables.todos[id] = todo
        @changed.todos.push(todo)

    ###############################
    ##### Update Associations #####
    ###############################
    ##### These routines populate and update the @associations object
    ##### Associations are stored in a separate table since calculated columns are wiped whenever a record is updated
    ##### These contain pointers to related records. They are updated for new/changed, and deleted records
    ##### This allows us to incrementally update only changed records, or records related to changed records
    buildAssociationsStart = new Date
    @updateAssociations()

    #####################################
    ##### Update Calculated Columns #####
    #####################################
    # update calculated columns
    # note that we mutate existing records in place!
    # various GUI components may hold references to these records...
    # so in the GUI, we can't simply compare "new" and "old" records to see what has changed
    #  (because the "new" records may have changed under us!)
    calculatedColumnsStart = new Date

    ########################################################
    ##### Update columns related to records themselves #####
    ########################################################

    if @changed.officers
      for officer in @changed.officers
        officer.name = "#{officer.last_name}, #{officer.first_name}"

    if @changed.events
      for event in @changed.events
        if !event.show_in_ongoing
          event.duration = @findIds('event_dates', @associations.events[event.id].event_date_ids).sort(eventDateSort).length
        else
          event.duration = 'Ongoing'

    if @changed.clients
      for client in @changed.clients
        client.terms_status  = if client.terms_date_received  then 'Rcvd' else (if client.terms_date_sent  then 'Sent' else '')
        client.safety_status = if client.safety_date_received then 'Rcvd' else (if client.safety_date_sent then 'Sent' else '')

    ################################################################
    ##### Update columns that relate directly to another table #####
    ################################################################

    if @changed.officers || @changed.accounts || @recordsToDelete.accounts
      # only account records for officers are sent to Office Zone
      @updateChangedForAssociation('officers', 'accounts', 'user_id')
      for officer in @changed.officers || []
        account = @findId('accounts', @associations.officers[officer.id].account_id)
        officer = @findId('officers', account.user_id)
        officer.locked_out = account.locked

    if @changed.gigs || @changed.jobs || @recordsToDelete.jobs
      @updateChangedForAssociation('gigs', 'jobs')
      for gig in @changed.gigs || []
        job = @findId('jobs', gig.job_id)
        gig.job_name = if job? then job.name else ''

    if @changed.gigs || @changed.events || @recordsToDelete.events
      @updateChangedForAssociation('gigs', 'events')
      for gig in @changed.gigs || []
        event = @findId('events', gig.event_id)
        gig.event_name = event.name
        gig.date_start = event.date_start
        gig.date_end = event.date_end
        gig.event_status = event.status

    if @changed.events || @changed.gig_requests || @recordsToDelete.gig_requests
      @updateChangedForAssociation('events', 'gig_requests')
      for event in @changed.events || []
        event.n_gig_requests = 0
        event.n_gig_requests_applicant = 0
        event.n_gig_requests_spare = 0
        for gig_request in @findIds('gig_requests', @associations.events[event.id].gig_request_ids)
          continue if gig_request.gig_id?
          status = @findId('prospects', gig_request.prospect_id).status
          continue if status == 'IGNORED'
          if status == 'APPLICANT'
            event.n_gig_requests_applicant += 1
          else if gig_request.spare
            event.n_gig_requests_spare += 1
          else
            event.n_gig_requests += 1

    if @changed.gig_requests || @changed.events || @recordsToDelete.events
      @updateChangedForAssociation('gig_requests', 'events')
      for gig_request in @changed.gig_requests || []
        event = @findId('events', gig_request.event_id)
        prospect = @findId('prospects', gig_request.prospect_id)
        gig_request.event_name = event?.name
        gig_request.date_start = event?.date_start
        gig_request.date_end   = event?.date_end
        gig_request.skills = ''
        skillTypes = ['SOME', 'MEDIUM', 'HIGH']
        if event?.has_bar == true && prospect?.bar_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-bar-color'>B</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_festivals == true && prospect?.festival_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-festivals-color'>F</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_hospitality == true && prospect?.hospitality_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-hospitality-color'>H</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_sport == true && prospect?.sport_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-sport-color'>S</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_promotional == true && prospect?.promo_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-promotional-color'>P</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_retail == true && prospect?.retail_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-retail-color'>R</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_office == true && prospect?.office_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-office-color'>O</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_warehouse == true && prospect?.warehouse_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-and-interest-padding-left skill-interest-warehouse-color'>L</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"

#        if prospect?.bar_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-bar-color'>B</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.festival_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-festivals-color'>F</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.hospitality_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-hospitality-color'>H</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.sport_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-sport-color'>S</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.promo_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-promotional-color'>P</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.retail_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-retail-color'>R</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.office_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-office-color'>O</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.warehouse_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-and-interest-padding-left skill-interest-warehouse-color'>L</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"

    if @changed.events || @changed.expenses || @recordsToDelete.expenses
      @updateChangedForAssociation('events', 'expenses')
      for event in @changed.events || []
        event.has_expenses = @associations.events[event.id].expense_ids.length > 0

    if @changed.prospects|| @changed.gig_requests || @recordsToDelete.gig_requests
      @updateChangedForAssociation('prospects', 'gig_requests')
      for prospect in @changed.prospects || []
        prospect.has_gig_request_in_year = {}
        for gig_request in @findIds('gig_requests', @associations.prospects[prospect.id].gig_request_ids)
          gig_request.size = ''
          continue unless !gig_request.gig_id? && gig_request.date_end.getTime() > today.getTime()
          gig_request.size = prospect.prospect_character
          if gig_request.spare
            prospect.has_spare_gig_requests = true
          else
            prospect.has_gig_requests = true
          prospect.has_gig_request_in_year[gig_request.date_start.getFullYear()] = true
          prospect.has_gig_request_in_year[gig_request.date_end.getFullYear()] = true

    if @changed.prospects || @changed.gigs || @recordsToDelete.gigs
      @updateChangedForAssociation('prospects', 'gigs')

      for prospect in @changed.prospects || []
        prospect.has_gig_in_year = {}
        gigs = @findIds('gigs', @associations.prospects[prospect.id].gig_ids)
        if gigs?
          with_rating = gigs.filter((g) -> g.rating?)
          if with_rating.length > 0
            prospect.avg_rating =
              # +float.toFixed(2) is a trick to round a fractional number off to 2 decimal places, but leave whole numbers as is
              +((with_rating.reduce(((sum,gig) -> sum + gig.rating), 0) / with_rating.length).toFixed(2))
          else
            prospect.avg_rating = prospect.rating
          live = false
          n_gigs = 0
          for gig in gigs
            if gig.event_status in ['OPEN', 'HAPPENING', 'FINISHED'] && gig.status == 'Active'
              live = true
            if gig.date_start.getTime() <= today.getTime()
              n_gigs = n_gigs+1
            prospect.has_gig_in_year[gig.date_start.getFullYear()] = true
            prospect.has_gig_in_year[gig.date_end.getFullYear()] = true
          prospect.is_live = live
          prospect.n_gigs = n_gigs
        else
          prospect.avg_rating = prospect.rating
          prospect.is_live = false
          prospect.n_gigs = 0

    if @changed.prospects
      for prospect in @changed.prospects
        diffMs = Date.now() - prospect.date_of_birth
        prospect.age = Math.abs(new Date(diffMs).getUTCFullYear() - 1970)
        prospect.name = "#{prospect.last_name}, #{prospect.first_name}, #{prospect.avg_rating}, #{prospect.n_gigs}, #{prospect.flag_photo}"
        prospect.skills = ""
        skillTypes = ['SOME', 'MEDIUM', 'HIGH']
        if prospect.bar_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-bar-color'>B</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.festival_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-festivals-color'>F</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.hospitality_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-hospitality-color'>H</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.sport_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-sport-color'>S</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.promo_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-promotional-color'>P</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.retail_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-retail-color'>R</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.office_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-interest-office-color'>O</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"
        if prospect.warehouse_skill in skillTypes
          prospect.skills += "<p class='interest-and-skill-label skill-and-interest-padding-left skill-interest-warehouse-color'>L</p>"
        else
          prospect.skills += "<p class='interest-and-skill-label'></p>"

    if @changed.gig_requests || @changed.prospects || @recordsToDelete.prospects
      @updateChangedForAssociation('gig_requests', 'prospects')
      for gig_request in @changed.gig_requests || []
        prospect = @findId('prospects', gig_request.prospect_id)
        event = @findId('events', gig_request.event_id)
        gig_request.avg_rating        = prospect.avg_rating
        gig_request.n_gigs            = prospect.n_gigs
        gig_request.good_sport        = prospect.good_sport
        gig_request.good_bar          = prospect.good_bar
        gig_request.good_promo        = prospect.good_promo
        gig_request.good_hospitality  = prospect.good_hospitality
        gig_request.good_management   = prospect.good_management
        gig_request.region_name       = regionForRecord(prospect)
        gig_request.name              = prospect.last_name + ", " + prospect.first_name
        gig_request.gender            = prospect.gender
        gig_request.age               = prospect.age
        gig_request.status            = prospect.status
        gig_request.no_show_contracts                 = prospect.no_show_contracts
        gig_request.cancelled_eighteen_hrs_contracts  = prospect.cancelled_eighteen_hrs_contracts
        gig_request.prospect_character                = prospect.prospect_character
        gig_request.size                              = prospect.prospect_character
        gig_request.skills = ''
        skillTypes = ['SOME', 'MEDIUM', 'HIGH']

        if event?.has_bar == true && prospect?.bar_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-bar-color'>B</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_festivals == true && prospect?.festival_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-festivals-color'>F</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_hospitality == true && prospect?.hospitality_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-hospitality-color'>H</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_sport == true && prospect?.sport_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-sport-color'>S</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_promotional == true && prospect?.promo_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-promotional-color'>P</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_retail == true && prospect?.retail_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-retail-color'>R</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_office == true && prospect?.office_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-interest-office-color'>O</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"
        if event?.has_warehouse == true && prospect?.warehouse_skill in skillTypes
          gig_request.skills += "<p class='interest-and-skill-label skill-and-interest-padding-left skill-interest-warehouse-color'>L</p>"
        else
          gig_request.skills += "<p class='interest-and-skill-label'></p>"

#        if prospect?.bar_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-bar-color'>B</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.festival_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-festivals-color'>F</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.hospitality_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-hospitality-color'>H</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.sport_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-sport-color'>S</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.promo_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-promotional-color'>P</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.retail_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-retail-color'>R</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.office_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-interest-office-color'>O</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"
#        if prospect?.warehouse_skill in skillTypes
#          gig_request.skills += "<p class='interest-and-skill-label skill-and-interest-padding-left skill-interest-warehouse-color'>L</p>"
#        else
#          gig_request.skills += "<p class='interest-and-skill-label'></p>"

    if @changed.questionnaires || @changed.prospects
      @updateChangedForAssociation('prospects', 'questionnaires')
      for prospects in @changed.prospects || []
        questionnaire = @findId('questionnaires', @associations.prospects[prospect.id].questionnaire_id)
        if questionnaire?
          prospect.weekends_work                = questionnaire.weekends_work
          prospect.week_days_work               = questionnaire.week_days_work
          prospect.day_shifts_work              = questionnaire.day_shifts_work
          prospect.evening_shifts_work          = questionnaire.evening_shifts_work
          prospect.bar_management_experience    = questionnaire.bar_management_experience
          prospect.staff_leadership_experience  = questionnaire.staff_leadership_experience
          prospect.festival_event_bar_management_experience = questionnaire.festival_event_bar_management_experience
          prospect.event_production_experience  = questionnaire.event_production_experience
          prospect.contact_via_text             = questionnaire.contact_via_text
          prospect.contact_via_whatsapp         = questionnaire.contact_via_whatsapp
          prospect.contact_via_email            = questionnaire.contact_via_email
          prospect.contact_via_telephone        = questionnaire.contact_via_telephone
          prospect.food_health_level_two_qualification      = questionnaire.food_health_level_two_qualification
          prospect.english_personal_licence_qualification   = questionnaire.english_personal_licence_qualification
          prospect.dbs_qualification                        = questionnaire.dbs_qualification
          prospect.scottish_personal_licence_qualification  = questionnaire.scottish_personal_licence_qualification
          prospect.bar_and_hospitality               = questionnaire.has_bar_and_hospitality != null && questionnaire.has_bar_and_hospitality != 'NONE'
          prospect.sport_and_outdoor                 = questionnaire.has_sport_and_outdoor != null && questionnaire.has_sport_and_outdoor != 'NONE'
          prospect.promotional_and_street_marketing  = questionnaire.has_promotional_and_street_marketing != null && questionnaire.has_promotional_and_street_marketing != 'NONE'
          prospect.merchandise_and_retail            = questionnaire.has_merchandise_and_retail != null && questionnaire.has_merchandise_and_retail != 'NONE'
          prospect.reception_and_office_admin        = questionnaire.has_reception_and_office_admin != null && questionnaire.has_reception_and_office_admin != 'NONE'
          prospect.festivals_and_concerts            = questionnaire.has_festivals_and_concerts != null && questionnaire.has_festivals_and_concerts != 'NONE'
      for questionnaire in @changed.questionnaires || []
        prospect = window.db.findId('prospects', questionnaire.prospect_id)
        if prospect?
          prospect.weekends_work                = questionnaire.weekends_work
          prospect.week_days_work               = questionnaire.week_days_work
          prospect.day_shifts_work              = questionnaire.day_shifts_work
          prospect.evening_shifts_work          = questionnaire.evening_shifts_work
          prospect.bar_management_experience    = questionnaire.bar_management_experience
          prospect.staff_leadership_experience  = questionnaire.staff_leadership_experience
          prospect.festival_event_bar_management_experience = questionnaire.festival_event_bar_management_experience
          prospect.event_production_experience  = questionnaire.event_production_experience
          prospect.contact_via_text             = questionnaire.contact_via_text
          prospect.contact_via_whatsapp         = questionnaire.contact_via_whatsapp
          prospect.contact_via_email            = questionnaire.contact_via_email
          prospect.contact_via_telephone        = questionnaire.contact_via_telephone
          prospect.food_health_level_two_qualification      = questionnaire.food_health_level_two_qualification
          prospect.english_personal_licence_qualification   = questionnaire.english_personal_licence_qualification
          prospect.dbs_qualification                        = questionnaire.dbs_qualification
          prospect.scottish_personal_licence_qualification  = questionnaire.scottish_personal_licence_qualification
          prospect.bar_and_hospitality               = questionnaire.has_bar_and_hospitality != null && questionnaire.has_bar_and_hospitality != 'NONE'
          prospect.sport_and_outdoor                 = questionnaire.has_sport_and_outdoor != null && questionnaire.has_sport_and_outdoor != 'NONE'
          prospect.promotional_and_street_marketing  = questionnaire.has_promotional_and_street_marketing != null && questionnaire.has_promotional_and_street_marketing != 'NONE'
          prospect.merchandise_and_retail            = questionnaire.has_merchandise_and_retail != null && questionnaire.has_merchandise_and_retail != 'NONE'
          prospect.reception_and_office_admin        = questionnaire.has_reception_and_office_admin != null && questionnaire.has_reception_and_office_admin != 'NONE'
          prospect.festivals_and_concerts            = questionnaire.has_festivals_and_concerts != null && questionnaire.has_festivals_and_concerts != 'NONE'

    if @changed.gigs || @changed.prospects || @recordsToDelete.prospects
      @updateChangedForAssociation('gigs', 'prospects')
      for gig in @changed.gigs || []
        prospect = @findId('prospects', gig.prospect_id)
        gig.bar_license_type = prospect.bar_license_type
        gig.name             = "#{prospect.last_name}, #{prospect.first_name}, #{prospect.avg_rating}, #{prospect.flag_photo}"
        gig.age              = prospect.age
        gig.has_ni           = prospect.ni_number
        gig.has_tax_choice   = prospect.tax_choice?
        gig.has_identity     = prospect.id_number? && prospect.id_type? && prospect.id_sighted? && (prospect.id_type != 'Pass Visa' || prospect.visa_number?) && (prospect.id_type != 'Work/Residency Visa' || prospect.share_code? || prospect.visa_number?) && (!prospect.visa_expiry? || (prospect.visa_expiry.getTime() >= today.getTime()))
        gig.avg_rating       = prospect.avg_rating
        gig.dbs_qualification_type    = prospect.dbs_qualification_type
        gig.email_status              = prospect.email_status
        gig.left_voice_message        = prospect.left_voice_message
        gig.no_show_contracts         = prospect.no_show_contracts
        gig.cancelled_eighteen_hrs_contracts         = prospect.cancelled_eighteen_hrs_contracts
        gig.prospect_character        = prospect.prospect_character
        gig.texted_date               = prospect.texted_date

    if @changed.gigs || @changed.gig_tax_weeks || @recordsToDelete.gig_tax_weeks
      @updateChangedForAssociation('gigs', 'gig_tax_weeks')
      for gig in @changed.gigs || []
        gig.tax_week ||= {}
        for gig_tax_week in @findIds('gig_tax_weeks', @associations.gigs[gig.id].gig_tax_week_ids)
          gig.tax_week[gig_tax_week.tax_week_id] = gig_tax_week

    ##### Interview Slot and bulk id will not change for an interview, so we don't need to check those for changes
    if @changed.prospects || @changed.interviews || @recordsToDelete.interviews
      @updateChangedForAssociation('prospects', 'interviews')
      for prospect in @changed.prospects || []
        if interview = @findId('interviews', @associations.prospects[prospect.id].interview_id)
          prospect.interview_id = interview.id
          interview_slot = @findId('interview_slots', interview.interview_slot_id)
          prospect.interview_slot_id = interview_slot.id
          interview_block = @findId('interview_blocks', interview_slot.interview_block_id)
          prospect.bulk_interview_id_and_date = "#{interview_block.bulk_interview_id}_#{printDate(interview_block.date)}"
          prospect.telephone_call_interview = interview.telephone_call_interview
          prospect.video_call_interview = interview.video_call_interview
        else
          prospect.interview_id = undefined
          prospect.interview_slot_id = undefined
          prospect.bulk_interview_id_and_date = undefined
          prospect.telephone_call_interview = undefined
          prospect.video_call_interview = undefined

    if @changed.assignments || @changed.shifts || @recordsToDelete.shifts
      @updateChangedForAssociation('assignments', 'shifts')
      for assignment in @changed.assignments || []
        assignment.tax_week_id = @findId('shifts', assignment.shift_id).tax_week_id

    if @changed.events || @changed.pay_weeks || @recordsToDelete.pay_weeks
      @updateChangedForAssociation('events', 'pay_weeks')
      for event in @changed.events || []
        event.payroll_pending = {}
        event.payroll_submitted = {}
        event.payroll_to_approve = {}
        for pay_week in @findIds('pay_weeks', @associations.events[event.id].pay_week_ids)
          event.payroll_pending[pay_week.tax_week_id] ||= (pay_week.status == 'PENDING')
          event.payroll_submitted[pay_week.tax_week_id] ||= (pay_week.status == 'SUBMITTED')
          event.payroll_to_approve[pay_week.tax_week_id] ||= (pay_week.status == 'TO_APPROVE')

    if @changed.tax_weeks || @changed.pay_weeks || @recordsToDelete.pay_weeks
      @updateChangedForAssociation('tax_weeks', 'pay_weeks')
      for tax_week in @changed.tax_weeks || []
        pay_weeks = @findIds('pay_weeks', @associations.tax_weeks[tax_week.id].pay_week_ids)
        tax_week.status_pending    = pay_weeks.filter((pay_week) -> pay_week.status == 'PENDING').length > 0
        tax_week.status_submitted  = pay_weeks.filter((pay_week) -> pay_week.status == 'SUBMITTED').length > 0
        tax_week.status_to_approve = pay_weeks.filter((pay_week) -> pay_week.status == 'TO_APPROVE').length > 0

    if @changed.tax_years || @changed.tax_weeks || @recordsToDelete.tax_weeks
      @updateChangedForAssociation('tax_years', 'tax_weeks')
      for tax_year in @changed.tax_years || []
        tax_weeks = @findIds('tax_weeks', @associations.tax_years[tax_year.id].tax_week_ids)
        tax_year.status_pending    = tax_weeks.filter((tax_week) -> tax_week.status_pending).length > 0
        tax_year.status_submitted  = tax_weeks.filter((tax_week) -> tax_week.status_submitted).length > 0
        tax_year.status_to_approve = tax_weeks.filter((tax_week) -> tax_week.status_to_approve).length > 0

    if @changed.events || @changed.event_dates || @recordsToDelete.event_dates
      @updateChangedForAssociation('events', 'event_dates')
      for event in @changed.events || []
        event.event_dates = {}
        event.event_dates['ALL'] = @findIds('event_dates', @associations.events[event.id].event_date_ids).sort(eventDateSort)
        for event_date in event.event_dates['ALL']
          event.event_dates[event_date.tax_week_id] ||= []
          event.event_dates[event_date.tax_week_id].push(event_date)
          event.event_dates['tax_week_id'] ||= []
          event.event_dates['tax_week_id'].push(event_date)
          currentTaxWeek = db.queryAll('tax_weeks', {includes_date: getToday()})[0]
          if event.show_in_ongoing == true
            event_dates = event.event_dates[event_date.tax_week_id]
            first_date = event_dates[0].date
            if dateInRange(first_date, currentTaxWeek.date_start, currentTaxWeek.date_end)
              event.ongoing_status = "HAPPENING"
            else
              event.ongoing_status = "OPEN"

    if @changed.tax_weeks || @changed.event_dates || @recordsToDelete.event_dates
      @updateChangedForAssociation('tax_weeks', 'event_dates')
      for tax_week in @changed.tax_weeks || []
        event_ids = @findIds('event_dates', @associations.tax_weeks[tax_week.id].event_date_ids).sort(eventDateSort).map((event_date) -> event_date.event_id).uniqueItems();
        tax_week.events = event_ids
        tax_week.active_events = @findIds('events', event_ids).filter((event) -> !((event.payroll_submitted[tax_week.id] && event.payroll_submitted[tax_week.id] == true) || event.status == 'CLOSED' || event.status == 'CANCELLED')).map((event) => event.id)
        tax_week.pending_events = @findIds('events', event_ids).filter((event) -> event.payroll_pending[tax_week.id]).map((event) => event.id)
        tax_week.to_approve_events = @findIds('events', event_ids).filter((event) -> event.payroll_to_approve[tax_week.id]).map((event) => event.id)

    if @changed.events || @changed.assignments || @recordsToDelete.assignments
      @updateChangedForAssociation('events', 'assignments')
      for event in @changed.events || []
        event.staff_needed_for_assignments = {}
        for assignment in @findIds('assignments', @associations.events[event.id].assignment_ids)
          tax_week_id = @findId('shifts', assignment.shift_id).tax_week_id
          event.staff_needed_for_assignments[tax_week_id] ||=0
          event.staff_needed_for_assignments[tax_week_id] += assignment.staff_needed
          event.staff_needed_for_assignments['needed_staff'] ||=0
          event.staff_needed_for_assignments['needed_staff'] += assignment.staff_needed

    if @changed.events || @changed.event_tasks || @recordsToDelete.event_tasks
      @updateChangedForAssociation('events', 'event_tasks')
      currentTaxWeek = db.queryAll('tax_weeks', {includes_date: getToday()})[0]
      for event in @changed.events || []
        event.n_tasks = 0
        event.n_incomplete_tasks = 0
        event.n_incomplete_tasks_planner = 0
        event.n_incomplete_tasks_this_week = 0
        for task in @findIds('event_tasks', @associations.events[event.id].event_task_ids)
          event.n_tasks += 1
          unless task.completed
            event.n_incomplete_tasks_planner += 1
            if event.reviewed_by_manager != null && event.size_id != null && window.db.findId('event_sizes', event.size_id).name in ['Medium+', 'Large', 'Complex']
              if event.show_in_ongoing == true
                event.n_incomplete_tasks += 1 if !dateInRange(event.date_start, currentTaxWeek.date_start, currentTaxWeek.date_end) && dateInRange(task.due_date, currentTaxWeek.date_start, currentTaxWeek.date_end)
              else
                event.n_incomplete_tasks += 1
            if event.size_id != null
              event.n_incomplete_tasks += 1
            event.n_incomplete_tasks_this_week += 1 if dateInRange(task.due_date, currentTaxWeek.date_start, currentTaxWeek.date_end)

    if @changed.officers || @changed.event_tasks || @recordsToDelete.event_tasks
      @updateChangedForAssociation('officers', 'event_tasks')
      currentTaxWeek = db.queryAll('tax_weeks', {includes_date: getToday()})[0]
      for officer in @changed.officers || []
        officer.n_incomplete_tasks_this_week = 0
        for task in @findIds('event_tasks', @associations.officers[officer.id].event_task_ids)
          if !task.completed && dateInRange(task.due_date, currentTaxWeek.date_start, currentTaxWeek.date_end)
            event = @findId('events', task.event_id)
            officer.n_incomplete_tasks_this_week += 1 if (!event || event.show_in_planner)

    ##########################################################################
    ##### Update columns that relate to one another through joins tables #####
    ##########################################################################

    # Note: If you are going to do more here than simply use the tag_id, you'll need to also check if @changed.tags changed
    if @changed.gigs || @changed.gig_tags || @recordsToDelete.gig_tags
      @updateChangedForAssociation('gigs', 'tags')
      for gig in @changed.gigs || []
        gig.tags = @associations.gigs[gig.id].tag_ids

    if @changed.gigs || @changed.assignments || @changed.gig_assignments || @recordsToDelete.gig_assignments
      @updateChangedForAssociation('gigs', 'gig_assignments')
      @updateChangedForAssociation('gigs', 'assignments')
      for gig in @changed.gigs || []
        gig.assignments = {}
        gig.assignments['ALL'] = []
        for assignment in @findIds('assignments', @associations.gigs[gig.id].assignment_ids)
          gig.assignments['ALL'].push(assignment.id)
          shift = @findId('shifts', assignment.shift_id)
          gig.assignments[shift.tax_week_id] ||= []
          gig.assignments[shift.tax_week_id].push(assignment.id)

    if @changed.prospects || @changed.gigs || @recordsToDelete.gigs
      @updateChangedForAssociation('prospects', 'gigs')
      last_tax_week = @queryAll('tax_weeks', {includes_date: last_week})[0]
      this_tax_week = @queryAll('tax_weeks', {includes_date: today})[0]
      for prospect in @changed.prospects
        for gig in @findIds('gigs', @associations.prospects[prospect.id].gig_ids)
          event = @findId('events', gig.event_id)
          if event.status != 'CLOSED' && event.status != 'CANCELLED'
            prospect.has_assignments_this_week = true if gig.assignments[this_tax_week.id]?.length > 0
            prospect.has_assignments_last_week = true if gig.assignments[last_tax_week.id]?.length > 0

    if @changed.events || @changed.gigs || @recordsToDelete.gigs
      @updateChangedForAssociation('events', 'gigs')
      for event in @changed.events || []
        event.n_active_gigs = 0
        event.n_gig_assignments = {}
        for gig in @findIds('gigs', @associations.events[event.id].gig_ids)
          event.n_active_gigs += 1 if gig.status == "Active"
          for tax_week_id, assignment_ids of gig.assignments
            event.n_gig_assignments[tax_week_id] ||= 0
            event.n_gig_assignments[tax_week_id] += assignment_ids.length if tax_week_id != 'ALL' && assignment_ids.length > 0
            event.n_gig_assignments['tax_week'] ||= 0
            event.n_gig_assignments['tax_week'] += assignment_ids.length if tax_week_id != 'ALL' && assignment_ids.length > 0

    if @changed.assignments || @changed.gigs || @changed.gig_assignments || @recordsToDelete.gig_assignments
      @updateChangedForAssociation('assignments', 'gigs')
      for assignment in @changed.assignments || []
        assignment.n_assigned = 0
        assignment.n_confirmed = 0
        for gig in @findIds('gigs', @associations.assignments[assignment.id].gig_ids)
          assignment.n_assigned += 1
          assignment.n_confirmed += 1 if gig.tax_week?[assignment.tax_week_id]?.confirmed

    if @changed.bulk_interviews || @changed.events || @changed.bulk_interview_events || @recordsToDelete.bulk_interview_events
      @updateChangedForAssociation('bulk_interviews', 'events')
      for bulk_interview in @changed.bulk_interviews || []
        bulk_interview.event_names = @findIds('events', @associations.bulk_interviews[bulk_interview.id].event_ids).map((event) -> event.name).sort().join(', ')

    if @changed.locations || @changed.shifts || @changed.assignments || @recordsToDelete.assignments
      @updateChangedForAssociation('locations', 'assignments')
      @updateChangedForAssociation('locations', 'shifts')
      for location in @changed.locations || []
        sorted_shifts = @findIds('shifts', @associations.locations[location.id].shift_ids).sort(shiftSort)
        location.earliest_shift_id = if sorted_shifts.length > 0 then sorted_shifts[0].id else undefined

    if @changed.events || @changed.event_clients
      @updateChangedForAssociation('event_clients', 'events')
      for eventClient in @changed.event_clients || []
        event = @findId('events', eventClient.event_id)
        eventClient.event_name       = event?.name
        eventClient.event_status     = event?.status
        eventClient.event_date_start = event?.date_start
        eventClient.event_date_end   = event?.date_end
        eventClient.event_requires_booking = event?.requires_booking

    if @changed.events || @changed.clients || @changed.event_clients || @recordsToDelete.event_clients
      @updateChangedForAssociation('events', 'event_clients')
      for event in @changed.events || []
        event.client_ids = @associations.events[event.id].client_ids
        event.client_names = @findIds('clients', event.client_ids).map((eventClient) -> eventClient.name).sort().join(', ')

    if @changed.clients || @changed.events || @changed.event_clients || @recordsToDelete.event_clients
      @updateChangedForAssociation('clients', 'event_clients')
      @updateChangedForAssociation('clients', 'events')
      for client in @changed.clients || []
        client.event_ids = []
        client.future_event_ids = []
        for event in @findIds('events', @associations.clients[client.id].event_ids)
          if event.date_start && event.date_start.getTime() <= today.getTime() then client.event_ids.push(event.id) else client.future_event_ids.push(event.id)

    ##############################################################
    ##### Too convoluted to fit in our nice categories above #####
    ##############################################################

    ##### Bookings/Invoices are connected to event_clients, which are join tables for events/clients
    ##### I could probably have made a OneToManyThrough association, but that it's really only needed for this one exception
    ##### To compensate, I used 'updateChangedForException' to trigger recalculation
    if @changed.bookings
      @updateChangedForAssociation('event_clients', 'bookings')

    if @changed.events || @changed.bookings || @recordsToDelete.bookings || @changed.event_clients || @recordsToDelete.event_clients
      @updateChangedForAssociation('events', 'event_clients')
      for event in @changed.events || []
        event_client_ids = @associations.events[event.id].event_client_ids
        booking_ids = @findIds('event_clients', event_client_ids).filter((event_client) => @associations.event_clients[event_client.id].booking_id != null).map((event_client) => @associations.event_clients[event_client.id].booking_id)
        bookingStatus = []
        for booking in @findIds('bookings', booking_ids)
          status = ''
          status = 'Sent' if booking.date_sent
          status = 'Rcvd' if booking.date_received
          bookingStatus.push(status) if status != ''
        event.booking_status = if bookingStatus.length > 0 then bookingStatus.join(', ') else (if event.requires_booking then 'Y' else 'N/A')

    if @changed.invoices || @changed.clients || @changed.events || @changed.bookings || @recordsToDelete.bookings || @changed.event_clients || @recordsToDelete.event_clients
      @updateChangedForAssociation('invoices', 'event_clients')
      for invoice in @changed.invoices || []
        event_client = @findId('event_clients', invoice.event_client_id)
        event = @findId('events', event_client.event_id)
        client = @findId('clients', event_client.client_id)
        booking = @findId('bookings', @associations.event_clients[event_client.id].booking_id)
        invoice.event_name = event.name
        invoice.event_dates = printDateSpan(event.date_start, event.date_end)
        invoice.client_name = client.name
        invoice.booking_invoicing_notes = booking && booking.invoicing || ''
        invoice.booking_id = booking.id if booking
        invoice.tax_week = printTaxWeek(@findId('tax_weeks', invoice.tax_week_id))

    ##########################
    ##### Delete Records #####
    ##########################
    # We delete records at the end because we need to reference them in @updateChangedForAssociation
    if @recordsToDelete
      for table,record_ids of @recordsToDelete when record_ids.length > 0
        @deleteRecords(table,record_ids)

    refreshCallBacksStart = new Date

    for c in @refreshCallbacks
      if arrayContainsElementInAnotherArray(c.tables, Object.keys(@changed).concat(Object.keys(@recordsToDelete)))
        c.callback(updateType)

    #console.info("LoadTablesTime:", buildAssociationsStart - importTableStart)
    #console.info("BuildAssociationsTime", calculatedColumnsStart - buildAssociationsStart)
    #console.info("CalculateColumnsTime:", refreshCallBacksStart - calculatedColumnsStart)
    #console.info("CallbacksTime:", (new Date) - refreshCallBacksStart)

  addAssociation: (config) ->
    @associationConfig.push(config)
    (@associationType[config.table1]||={})[config.table2] = config.type
    (@associationType[config.table2]||={})[config.table1] = (if config.type == 'OneToMany' then 'ManyToOne' else config.type)
    if config.type == 'ManyToMany'
      joinTableName = config.joinTable || config.table1.slice(0, -1) + '_' + config.table2
      (@associationJoinTableName[config.table1]||={})[config.table2] = joinTableName
      (@associationJoinTableName[config.table2]||={})[config.table1] = joinTableName
      (@associationType[config.table1]||={})[joinTableName] = 'OneToMany'
      (@associationType[config.table2]||={})[joinTableName] = 'OneToMany'
      (@associationType[joinTableName]||={})[config.table1] = 'ManyToOne'
      (@associationType[joinTableName]||={})[config.table2] = 'ManyToOne'



  deleteStaleAssociations: () ->
    for config in @associationConfig
      switch config.type
        when 'OneToOne'   then @deleteStaleOneToOneAssociation(config.table1, config.table2, config.idName1)
        when 'OneToMany'  then @deleteStaleOneToManyAssociation(config.table1, config.table2)
        when 'ManyToMany' then @deleteStaleManyToManyAssociation(config.table1, config.table2, config.joinTable)
        else throw "Invalid Association Type: #{config.type}"

  deleteStaleOneToOneAssociation: (sourceTable, targetTable, sourceIdName=null) ->
    return unless @associations[sourceTable] && (@changed[targetTable] || @recordsToDelete[targetTable])
    sourceIdName = sourceIdName || sourceTable.slice(0, -1) + '_id'
    targetIdName = targetTable.slice(0, -1) + '_id'
    for targetId in (@recordsToDelete[targetTable] || []).concat((@changed[targetTable] || []).map((target) -> target.id))
      if target = @findId(targetTable, targetId)
        sourceId = target[sourceIdName]
        if source = @associations[sourceTable][sourceId]
          source[targetIdName] = null
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  deleteStaleOneToManyAssociation: (sourceTable, targetTable) ->
    return unless @associations[sourceTable] && (@changed[targetTable] || @recordsToDelete[targetTable])
    sourceIdName = sourceIdName || sourceTable.slice(0, -1) + '_id'
    targetIdNamePlural = targetTable.slice(0, -1) + '_ids'
    for targetId in (@recordsToDelete[targetTable] || []).concat((@changed[targetTable] || []).map((target) -> target.id) || [])
      if target = @findId(targetTable, targetId)
        sourceId = target[sourceIdName]
        if source = @associations[sourceTable][sourceId]
          source[targetIdNamePlural].delete(targetId)
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  deleteStaleManyToManyAssociation: (table1, table2) ->
    joinTable = @associationJoinTableName[table1]?[table2]
    return unless @associations[table1] && @associations[table2]  && (@changed[joinTable] || @recordsToDelete[joinTable])
    idName1 = table1.slice(0, -1) + '_id'
    idName1Plural = idName1 + 's'
    idName2 = table2.slice(0, -1) + '_id'
    idName2Plural = idName2 + 's'
    for joinId in (@recordsToDelete[joinTable] || []).concat((@changed[joinTable] || []).map((join) -> join.id))
      if join = @findId(joinTable, joinId)
        id1 = join[idName1]
        id2 = join[idName2]
        if source1 = @associations[table1][id1]
          source1[idName2Plural].delete(id2)
        if source2 = @associations[table2][id2]
          source2[idName1Plural].delete(id1)
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  updateAssociations: () ->
    for config in @associationConfig
      switch config.type
        when 'OneToOne'   then @updateOneToOneAssociation(config.table1, config.table2, config.idName1)
        when 'OneToMany'  then @updateOneToManyAssociation(config.table1, config.table2)
        when 'ManyToMany' then @updateManyToManyAssociation(config.table1, config.table2)
        else raise "Invalid Association Type: #{config.type}"

  updateOneToOneAssociation: (sourceTable, targetTable, sourceIdName=null) ->
    return unless @changed[sourceTable] || @changed[targetTable] || @recordsToDelete[targetTable]
    sourceIdName = sourceIdName || sourceTable.slice(0, -1) + '_id'
    targetIdName = targetTable.slice(0, -1) + '_id'
    sourceAssociationTable = @associations[sourceTable]||={}
    for sourceRecord in @changed[sourceTable] || []
      (sourceAssociationTable[sourceRecord.id] ||= {})[targetIdName] ||= null
    for target in @changed[targetTable] || []
      if sourceId = target[sourceIdName]
        sourceAssociationTable[target[sourceIdName]] && sourceAssociationTable[target[sourceIdName]][targetIdName] = target.id
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  updateOneToManyAssociation: (sourceTable, targetTable) ->
    return unless @changed[sourceTable] || @changed[targetTable] || @recordsToDelete[targetTable]
    sourceIdName = sourceTable.slice(0, -1) + '_id'
    targetIdNamePlural = targetTable.slice(0, -1) + '_ids'
    sourceAssociationTable = @associations[sourceTable]||={}
    for sourceRecord in @changed[sourceTable] || []
      (sourceAssociationTable[sourceRecord.id] ||= {})[targetIdNamePlural] ||= []
    for target in @changed[targetTable] || []
      if sourceId = target[sourceIdName]
        sourceAssociationTable[target[sourceIdName]][targetIdNamePlural].pushIfUnique(target.id)
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  updateManyToManyAssociation: (table1, table2) ->
    joinTable = @associationJoinTableName[table1]?[table2]
    return unless @changed[table1] || @changed[table2] || @changed[joinTable] || @recordsToDelete[joinTable]
    idName1 = table1.slice(0, -1) + '_id'
    idName1Plural = idName1 + 's'
    idName2 = table2.slice(0, -1) + '_id'
    idName2Plural = idName2 + 's'
    associationTable1 = @associations[table1]||={}
    associationTable2 = @associations[table2]||={}
    for record1 in @changed[table1] || []
      (associationTable1[record1.id] ||= {})[idName2Plural] ||= []
    for record2 in @changed[table2] || []
      (associationTable2[record2.id] ||= {})[idName1Plural] ||= []
    for join in @changed[joinTable] || []
      associationTable1[join[idName1]][idName2Plural].pushIfUnique(join[idName2])
      associationTable2[join[idName2]][idName1Plural].pushIfUnique(join[idName1])
    undefined # prevent coffeescript from building a return array when routine ends with a for loop

  ###### If a associated record changed, mark the record it points to as changed
  updateChangedForAssociation: (primaryTable, associatedTable, primaryIdName=null) ->
    joinTable = @associationJoinTableName[primaryTable]?[associatedTable]
    return if @lastRefreshed == null || !(@changed[associatedTable] || @recordsToDelete[associatedTable] || @recordsToDelete[joinTable])

    changedIds = (@changed[primaryTable] || []).map((record) -> record.id)
    associatedIds = (@changed[associatedTable] || []).map((record) -> record.id).concat(@recordsToDelete[associatedTable] || [])

    primaryIdName = primaryIdName || primaryTable.slice(0, -1) + '_id'
    primaryIdNamePlural = primaryIdName + 's'

    ##### Mark as changed any that had an associated join deleted
    changedIdsFromAssociation = (@recordsToDelete[joinTable] || []).map((id) => @findId(joinTable, id)[primaryIdName] || [])

    associationType = @associationType[associatedTable][primaryTable]
    if associationType == 'OneToOne' || associationType == 'ManyToOne'
      for associatedId in associatedIds
        primaryId = @findAssociatedProperty(associatedTable, associatedId, primaryIdName)
        changedIdsFromAssociation.push(primaryId)
    else if associationType == 'OneToMany' || associationType == 'ManyToMany'
      for associatedId in associatedIds
        for primaryId in @findAssociatedProperty(associatedTable, associatedId, primaryIdNamePlural) || []
          changedIdsFromAssociation.push(primaryId)
    else
      throw "Could not find association for #{associatedTable} to #{primaryTable}. Do you need to setup Associations for these tables?"
    newPrimaryIds = getNewElements(changedIds, changedIdsFromAssociation)
    Array.prototype.push.apply((@changed[primaryTable] ||= []), @findIds(primaryTable, newPrimaryIds)) if newPrimaryIds.length > 0
    undefined

  findAssociatedProperty: (tableName, id, property) ->
    @findId(tableName, id)?[property] || @associations[tableName]?[id]?[property]

  updateTable: (tableName, records) ->
    table = (@tables[tableName] ||= {})
    for record in records
      table[record.id] = record
    @indexes[tableName] = {}

  deleteRecords: (tableName, recordIds) ->
    table = (@tables[tableName] ||= {})
    delete table[id] for id in recordIds
    @indexes[tableName] = {}

  onUpdate: (tables, callback) ->
    tables = [tables] unless Array.isArray(tables)
    @refreshCallbacks.push({tables: tables, callback: callback})

  addFilters: (table, filters) ->
    tableFilters = (@filterFunctions[table] ||= {})
    tableFilters[name] = func for name,func of filters

  # QUERYING THE DB
  # Right now we don't do any kind of caching for queries --
  #   with all the data in memory, even queries on 20,000+ records seem to be very fast

  findId: (table, id) ->
    @tables[table]?[id]

  findIds: (table, ids) ->
    if table = @tables[table]
      (table[id] for id in ids when table[id])
    else
      throw new Error("No such table exists: #{table}")

  # 'query' returns [records, total number of records available without offset/limit]
  query: (tableName, filters, sort, sortAscend=true, search, offset, limit) ->
    result = @queryAll(tableName, filters, sort, sortAscend, search)
    if offset+limit > result.length
      limit = result.length - offset
    if limit < 0
      limit = 0
    [result[offset...(offset+limit)], result.length]

  queryAll: (tableName, filters, sort, sortAscend=true, search) ->
    table = @tables[tableName]
    result = (record for id,record of table)
    result = @filter(tableName, result, filters)

    if search && search.match(/\S/) # must have at least 1 non-whitespace char
      search = search.split(/\s+/).map((word) -> new RegExp("\\b"+word.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'i'))
      result = result.filter((record) ->
        search.every((regex) -> regex.test(record.name || "#{record.last_name}, #{record.first_name}")))

    if sort?
      key_func = if typeof(sort) == 'string'
        (obj) ->
          k = obj[sort]
          k = k.toLowerCase() if typeof(k) == 'string'
          k
      else if typeof(sort) == 'function'
        sort
      else
        throw new Error("Don't know what to do with " + sort)

      # We modify the comparison functions by also comparing in such a way that nulls are considered
      #   'lower' than any other value
      # Check how many arguments the sort function has, and handle accordingly
      switch key_func.length
        # For a one-argument sort, does a simple transformation, perhaps generating a key from an object
        when 1
          if sortAscend
            result.sort((r1,r2) ->
              a = key_func(r1)
              b = key_func(r2)
              if a?
                if b?
                  if a > b then 1 else if a == b then 0 else -1
                else
                  1
              else if b?
                -1
              else
                0)
          else
            result.sort((r1,r2) ->
              a = key_func(r1)
              b = key_func(r2)
              if a?
                if b?
                  if a < b then 1 else if a == b then 0 else -1
                else
                  -1
              else if b?
                1
              else
                0)
        when 2
          # A two-argument sort will be a completely customized sort
          if sortAscend
            result.sort((a,b) ->
              if a?
                if b?
                  key_func(a,b)
                else
                  1
              else if b?
                -1
              else
                0)
          else
            result.sort((a,b) ->
              if a?
                if b?
                  (key_func(a, b) * -1)
                else
                  -1
              else if b?
                1
              else
                0)
        else
          throw new Error("Don't know what to do with " + sort)
    result

  indexOf: (tableName, filters, sort, sortAscend=true, search, recordId) ->
    result = @queryAll(tableName, filters, sort, sortAscend, search)
    for record, index in result
      return index if record.id == recordId
    null

  buildFilter: (table, name, value, next) ->
    if next
      if (filters = @filterFunctions[table]) && (func = filters[name])
        (record) -> func(record, value) && next(record)
      else
        (record) -> (record[name] == value) && next(record)
    else if (filters = @filterFunctions[table]) && (func = filters[name])
      (record) -> func(record, value)
    else
      (record) -> record[name] == value

  lookupTable: (tableName, columnName) ->
    tblIndexes = (@indexes[tableName] ||= {})
    if colIndex = tblIndexes[columnName]
      colIndex
    else
      colIndex = {}
      if table = @tables[tableName]
        for id,record of table
          records = (colIndex[record[columnName]] ||= [])
          records.push(record) unless @recordsToDelete?[tableName]?[id]
      tblIndexes[columnName] = colIndex

  filter: (tableName, records, filters) =>
    (filter = @buildFilter(tableName,name,value,filter)) for name,value of filters
    if filter
      records.filter(filter)
    else
      records

  initializeFilters: =>
    @addFilters('assignments',
      tax_week_id: (assignment, tax_week_id) =>
        assignment.tax_week_id == parseInt(tax_week_id)
      date: (assignment, date) =>
        @findId('shifts', assignment.shift_id).date.getTime() == date.getTime()
      job_id: (assignment, id) =>
        assignment.job_id == parseInt(id)
      shift_id: (assignment, id) =>
        assignment.shift_id == parseInt(id)
      location_id: (assignment, id) =>
        assignment.location_id == parseInt(id)
      created_this_year: (assignment, val) =>
        today = getToday()
        thisYear = today.getFullYear()
        if val == true
          assignment.created_at.getFullYear() == parseInt(thisYear,10)
    )

    @addFilters('bulk_interviews',
      status : (bi,val) =>
        if val == 'UPCOMING'
          bi.status == 'NEW' || bi.status == 'OPEN' || bi.status == 'HAPPENING'
        else
          bi.status == val
    )

    @addFilters('clients',
      active: (client, flag) =>
        client.active == (flag == 'true')
      search_flair_contact: (client, search) =>
        matchStringStart(client.flair_contact, search)
    )

    @addFilters('event_clients',
      future_only:   (event_client,val) =>
        event = @findId('events', event_client.event_id)
        try (event.date_start.getTime() > getToday().getTime()) == val catch e then e
      started_only:  (event_client,val) =>
        event = @findId('events', event_client.event_id)
        try (event.date_start.getTime() <= getToday().getTime()) == val catch e then e
    )

    @addFilters('events',
      status : (evt,val) =>
        if val == 'ACTIVE'
          evt.status != 'CLOSED' && evt.status != 'CANCELLED'
        else
          evt.status == val
      active: (evt,val) =>
        (evt.status != 'CLOSED' && evt.status != 'CANCELLED') == val
      in_tax_week: (evt, tax_week_id) =>
        tax_week = @findId('tax_weeks', tax_week_id)
        tax_week.events.hasItem(evt.id)
      category_id: (evt,val) =>
        evt.category_id == parseInt(val)
      year : (evt,val) =>
        evt.date_start.getFullYear() == parseInt(val,10)
      created_this_year: (evt, val) =>
        today = getToday()
        thisYear = today.getFullYear()
        if val == true
          evt.created_at.getFullYear() == parseInt(thisYear,10)
      month : (evt,val) =>
        evt.date_start.getMonth()== (parseInt(val,10) - 1)
      includes_date: (evt, date) =>
        dateInRange(date, evt.date_start, evt.date_end)
      overlaps_dates: (evt, dates) =>
        dates.sort(date_sort_asc)
        (evt.date_start.getTime() <= dates[1].getTime() && dates[0].getTime() <= evt.date_end.getTime())
      id: (evt,val) =>
        evt.id == parseInt(val,10)
      office_manager_id: (evt, val) =>
        val = parseInt(val, 10)
        isNaN(val) || (val == -1 && !evt.office_manager_id?) || evt.office_manager_id == val
      senior_manager_id: (evt, val) =>
        val = parseInt(val, 10)
        isNaN(val) || (val == -1 && !evt.senior_manager_id?) || evt.senior_manager_id == val
      search_client: (evt, search) =>
        matchStringStart(evt.client_names, search)
      region_name: (evt,val) =>
        regionForRecord(evt) == val
      has_tasks: (evt, val) =>
        (evt.n_tasks > 0) == val
      has_incomplete_tasks: (evt, val) =>
        (evt.n_incomplete_tasks_planner > 0) == val
      show_in_featured: (evt, val) =>
        (evt.show_in_featured) == true

    )

    @addFilters('event_tasks',
      template_id: (event_task, template_id) =>
        if template_id == 'Custom'
          !event_task.template_id?
        else
          event_task.template_id == parseInt(template_id)
      officer_id: (event_task, officer_id) =>
        event_task.officer_id == parseInt(officer_id, 10)
      region_id: (event_task, region_id) =>
        event = @findId('events', event_task.event_id)
        event.region_id == parseInt(region_id, 10)
      completed: (event_task, flag) =>
        if flag == 'To Do and Done Today'
          !event_task.completed || (event_task.completed_date.getTime() == getToday().getTime())
        else
          event_task.completed == (flag == 'true')
      due: (event_task, flag) =>
        (event_task.due_date.getTime() <= getToday().getTime()) == (flag == 'true')
      day_of_the_week: (event_task, day_of_the_week) =>
        event_task.due_date.getDay() == parseInt(day_of_the_week, 10)
      client_id: (event_task, client_id) =>
        event = @findId('events', event_task.event_id)
        event.client_ids.hasItem(client_id)
      due_in_this_or_future_tax_week: (event_task, flag) =>
        tax_week = @findId('tax_weeks', event_task.tax_week_id)
        (tax_week.date_end.getTime() >= getToday().getTime()) == flag
      tax_week_id: (event_task, tax_week_id) =>
        event_task.tax_week_id == parseInt(tax_week_id, 10)
      show_in_planner: (event_task, flag) =>
        event = @findId('events', event_task.event_id)
        (!event || event.show_in_planner) == flag
      ignore_canceled_events: (event_task, flag) =>
        if flag == true
          event = @findId('events', event_task.event_id)
          (event_task.event_id == null) || (event? && event.status != 'CANCELLED')
    )

    @addFilters('gigs',
      prospect_skills: (gig, skill) =>
        skillTypes = ['NONE', 'SOME', 'MEDIUM', 'HIGH']
        prs = @findId('prospects', gig.prospect_id)
        if skill == 'has_sports'
          prs.sport_skill in skillTypes
        else if skill == 'has_bar'
          prs.bar_skill in skillTypes
        else if skill == 'has_promotional'
          prs.promo_skill in skillTypes
        else if skill == 'has_retail'
          prs.retail_skill in skillTypes
        else if skill == 'has_office'
          prs.office_skill in skillTypes
        else if skill == 'has_festivals'
          prs.festival_skill in skillTypes
        else if skill == 'bar_manager'
          prs.bar_manager_skill == true
        else if skill == 'staff_leadership'
          prs.staff_leader_skill == true
        else if skill == 'has_hospitality'
          prs.hospitality_skill in skillTypes
        else if skill == 'has_warehouse'
          prs.warehouse_skill in skillTypes
      prospect_marketing: (gig, skill) =>
        prs = @findId('prospects', gig.prospect_id)
        if skill == 'has_sports'
          prs.has_sport_and_outdoor == true
        else if skill == 'has_bar'
          prs.has_bar_and_hospitality == true
        else if skill == 'has_promotional'
          prs.has_promotional_and_street_marketing == true
        else if skill == 'has_retail'
          prs.has_merchandise_and_retail == true
        else if skill == 'has_office'
          prs.has_reception_and_office_admin == true
        else if skill == 'has_festivals'
          prs.has_festivals_and_concerts == true
        else if skill == 'bar_manager'
          prs.has_bar_management_experience == true
        else if skill == 'staff_leadership'
          prs.has_staff_leadership_experience == true
        else if skill == 'festival_event_bar_management'
          prs.has_festival_event_bar_management_experience == true
        else if skill == 'event_production'
          prs.has_event_production_experience == true
        else if skill == 'has_hospitality'
          prs.has_hospitality_marketing == true
        else if skill == 'has_warehouse'
          prs.has_warehouse_marketing == true
      rating:        (gig,val)  -> gig.rating == parseInt(val,10)
      avg_rating: (gig, rating) =>
        prs = @findId('prospects', gig.prospect_id)
        if rating == 'None' && !prs.avg_rating
          true
        else
          prs.avg_rating >= rating
      manager_level: (gig,val) =>
        prs = @findId('prospects', gig.prospect_id)
        prs.manager_level == val
      team_size: (gig, val) =>
        prs = @findId('prospects', gig.prospect_id)
        if val == 'BIG'
          prs.big_teams == 'Yes'
        else if val == 'ALL'
          prs.all_teams == 'Yes'
        else if val == 'Bespoke'
          prs.bespoke == 'Yes'
        else
          false
      distance: (gig, dist_string) =>
        prs = @findId('prospects', gig.prospect_id)
        dist_values = dist_string.split(',')
        event_id = dist_values[0]
        min_dist = dist_values[1]
        max_dist = dist_values[2]
        event = @findId('events', event_id)
        if (coord1 = coordinatesForRecord(prs)) && (coord2 = coordinatesForRecord(event))
          dist = distanceBetweenPointsInMiles(coord1, coord2)
          (dist >= min_dist) and (dist < max_dist)
        else
          false
      confirmed_for_tax_week: (gig,confirmed_for_tax_week) =>
        if gig_tax_week = gig.tax_week[confirmed_for_tax_week.tax_week_id]
          gig_tax_week.confirmed == confirmed_for_tax_week.value
        else
          ##### If the tax week does not exist, then we assume the callback is set to false
          confirmed_for_tax_week.value == false
      miscellaneous_boolean: (gig, flag) => gig.miscellaneous_boolean == (flag == 'true')
      published: (gig, flag) => gig.published == (flag == 'true')
      has_ni:        (gig,flag) => gig.has_ni == (flag == 'true')
      profile: (gig, val) =>
        prs = @findId('prospects', gig.prospect_id)
        if val == '5' || val == '4.5' || val == '4' || val == '3.5' || val == '3'
          prs.avg_rating >= val
        else if val == 'TRAINING'
          event = @findId('events', gig.event_id)
          has_required_training =
            (if event.require_training_ethics           then prs.training_ethics           else true) &&
              (if event.require_training_customer_service then prs.training_customer_service else true) &&
              (if event.require_training_health_safety    then prs.training_health_safety    else true) &&
              (if event.require_training_sports           then prs.training_sports           else true) &&
              (if event.require_training_bar_hospitality  then prs.training_bar_hospitality  else true)
          has_required_training == true
        else if val == 'F' || val == 'M'
          prs.gender == val
      admin: (gig, val) =>
        prs = @findId('prospects', gig.prospect_id)
        if val == 'NI'
          gig.has_ni == true
        else if val == 'NO_NI'
          gig.has_ni == false
        else if val == 'TAX'
          gig.has_tax_choice == true
        else if val == 'NO_TAX'
          gig.has_tax_choice == false
        else if val == 'ID'
          gig.has_identity == true
        else if val == 'NO_ID'
          gig.has_identity == false
        else if val == 'BANK'
          (prs.bank_account_name? && prs.bank_sort_code? && prs.bank_account_no?) == true
        else if val == 'NO_BANK'
          (prs.bank_account_name? && prs.bank_sort_code? && prs.bank_account_no?) == false
        else if val == 'PHOTO'
          (prs.photo != null) == true
        else if val == 'EMPLOYEE' || val == 'EXTERNAL'
          @findId('prospects', gig.prospect_id).status == val
        else if val == 'LARGE_PHOTO'
          prs.photo != null && prs.has_large_photo
      patterns: (gig, value) =>
        prs = @findId('prospects', gig.prospect_id)
        if value == 'weekdays'
          prs.week_days_work == true
        else if value == 'weekends'
          prs.weekends_work == true
        else if value == 'day'
          prs.day_shifts_work == true
        else
          prs.evening_shifts_work == true
      coms: (gig, value) =>
        prs = @findId('prospects', gig.prospect_id)
        if value == 'email'
          prs.contact_via_email == true
        else if value == 'tele'
          prs.contact_via_telephone == true
        else if value == 'text'
          prs.contact_via_text == true
        else
          prs.contact_via_whatsapp == true
      prospect_qualifications: (gig, val) =>
        prs = @findId('prospects', gig.prospect_id)
        if val == 'qualification_dbs_basic'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Basic' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'qualification_dbs_enhanced'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'qualification_dbs_enhanced_barred'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced Barred List' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'no_qualification_dbs'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == false || prs.dbs_issue_date == null || prs.dbs_issue_date < twoYearsOld
        else if val == 'qualification_food_health_2'
          prs.food_health_level_two_qualification == true
        else if val == 'no_qualification_food_health_2'
          prs.food_health_level_two_qualification == false || prs.food_health_level_two_qualification == null
        else if val == 'c_19_tt'
          prs.has_c19_test == true
        else if val == 'no_c_19_tt'
          prs.has_c19_test == false || prs.has_c19_test == null
        else
          prs.bar_license_type == val
      has_identity:        (gig,flag) => gig.has_identity == (flag == 'true')
      has_tax_choice: (gig,flag) => gig.has_tax_choice == (flag == 'true')
      has_bank_info: (gig,flag) =>
        prs = @findId('prospects', gig.prospect_id)
        (prs.bank_account_name? && prs.bank_sort_code? && prs.bank_account_no?) == (flag == 'true')
      future: (gig,val) => (gig.date_start.getTime() >= getToday().getTime()) == val
      future_only:   (gig,val) =>
        event = @findId('events', gig.event_id)
        (event.date_start.getTime() > getToday().getTime()) == val
      started_only:  (gig,val) =>
        event = @findId('events', gig.event_id)
        (event.date_start.getTime() <= getToday().getTime()) == val
      has_photo: (gig,val) =>
        prs = @findId('prospects', gig.prospect_id)
        if val == 'LARGE'
          prs.photo != null && prs.has_large_photo
        else
          (prs.photo != null) == (val == 'true')
      ###### Check if this gig as an assignment that matches the assignment_id.
      ###### If no assignment_id provided, check if it matches any of the job, location, or shift
      # val: {assignment_id: assignment_id, job: job_id, location: location_id, shift: shift_id}
      assignment: (gig, val) =>
        if val.all_filtered_assignment_ids?
          filtered_assignments = gig.assignments['ALL'].filter((assignment_id) -> val.all_filtered_assignment_ids.hasItem(assignment_id))
        else
          filtered_assignments = gig.assignments['ALL']
        if val.assignment_id?
          if val.assignment_id == -1 #None
            if val.date
              assignment_matches = false
              for assignment_id in filtered_assignments
                assignment_matches = assignment_matches || @filterShiftLocationJobDateMatch(@findId('assignments', assignment_id), val)
              !assignment_matches
            else
              (filtered_assignments.length == 0)
          else if val.assignment_id == 0 #Any
            (filtered_assignments.length > 0)
          else
            filtered_assignments.hasItem(val.assignment_id)
        else
          assignment_matches = !(val.job_id?) && !(val.location_id?) && !(val.shift_id) && !(val.date)
          for assignment_id in filtered_assignments
            assignment_matches = assignment_matches || @filterShiftLocationJobDateMatch(@findId('assignments', assignment_id), val)
          assignment_matches

      tag_id: (gig, val) =>
        val = parseInt(val, 10)
        if((gig.tags.length < 1) && (val < 0)) then true else gig.tags.hasItem(parseInt(val, 10)) == true
      job_id: (gig, val) =>
        val = parseInt(val, 10)
        if((gig.job_id == null) && (val < 0)) then true else gig.job_id == val
      location_id: (gig, val) =>
        val = parseInt(val, 10)
        if((gig.location_id == null) && (val < 0)) then true else gig.location_id == val
      has_required_training: (gig, flag) =>
        event = @findId('events', gig.event_id)
        prs = @findId('prospects', gig.prospect_id)
        has_required_training =
          (if event.require_training_ethics           then prs.training_ethics           else true) &&
            (if event.require_training_customer_service then prs.training_customer_service else true) &&
            (if event.require_training_health_safety    then prs.training_health_safety    else true) &&
            (if event.require_training_sports           then prs.training_sports           else true) &&
            (if event.require_training_bar_hospitality  then prs.training_bar_hospitality  else true)
        has_required_training == (flag == 'true')
      qualifications: (gig, key) =>
        # Previous return value: prs[key]
        prs = @findId('prospects', gig.prospect_id)
        if key == 'qualification_dbs_basic'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Basic' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'qualification_dbs_enhanced'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'qualification_dbs_enhanced_barred'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced Barred List' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'no_qualification_dbs'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == false || prs.dbs_issue_date == null || prs.dbs_issue_date < twoYearsOld
        else if key == 'qualification_food_health_2'
          prs.food_health_level_two_qualification == true
        else if key == 'no_qualification_food_health_2'
          prs.food_health_level_two_qualification == false || prs.food_health_level_two_qualification == null
        else
          true
      assignment_email_type: (gig, taxWeekIdAndAssignmentEmailType) =>
        taxWeekId = taxWeekIdAndAssignmentEmailType[0]
        val = taxWeekIdAndAssignmentEmailType[1]
        if taxWeekId?
          if gig.tax_week[taxWeekId]
            emailType = gig.tax_week[taxWeekId].assignment_email_type
            switch val
              when 'None'
                !(emailType?) || emailType == ''
              when 'Any'
                emailType? && emailType != ''
              else
                emailType == val
          else
            val == 'None'
        else
          ##### If no Tax WeeK Specified, we don't filter by email
          true
      assignment_email_template_id: (gig, taxWeekIdAndAssignmentEmailTemplate) =>
        taxWeekId = taxWeekIdAndAssignmentEmailTemplate[0]
        val = taxWeekIdAndAssignmentEmailTemplate[1]
        if taxWeekId?
          if gig.tax_week[taxWeekId]
            if val == 'Any'
              gig.tax_week[taxWeekId].assignment_email_template_id
            else
              gig.tax_week[taxWeekId].assignment_email_template_id == parseInt(val, 10)
          else
            val == 'None'
        else
          ##### If no Tax WeeK Specified, we don't filter by email
          true
      prospect_status: (gig, val) =>
        @findId('prospects', gig.prospect_id).status == val
    )

    @addFilters('gig_assignments',
      tax_week_id: (gig_assignment, tax_week_id) =>
        @findId('assignments', gig_assignment.assignment_id).tax_week_id == parseInt(tax_week_id)
    )

    @addFilters('gig_requests',
      spare:        (gr,flag)   -> gr.spare == (flag == 'true')
      applied_job: (gr,val) =>
        val = parseInt(val, 10)
        gr.job_id == val
      not_applicant: (gr,val)   -> (gr.status != 'APPLICANT') == val
      ignored:       (gr,val)   -> (gr.status == 'IGNORED') == val
      future_only:   (gr,val)   -> (gr.date_end.getTime() > getToday().getTime()) == val
      has_required_training: (gr, flag) =>
        event = @findId('events', gr.event_id)
        prs = @findId('prospects', gr.prospect_id)
        has_required_training =
          (if event.require_training_ethics           then prs.training_ethics           else true) &&
            (if event.require_training_customer_service then prs.training_customer_service else true) &&
            (if event.require_training_health_safety    then prs.training_health_safety    else true) &&
            (if event.require_training_sports           then prs.training_sports           else true) &&
            (if event.require_training_bar_hospitality  then prs.training_bar_hospitality  else true)
        has_required_training == (flag == 'true')
      bar_license_type: (gr, val) =>
        prs = @findId('prospects', gr.prospect_id)
        prs.bar_license_type == val
      qualifications: (gr, key) =>
        # Previous return value: prs[key]
        prs = @findId('prospects', gr.prospect_id)
        if key == 'qualification_dbs_basic'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Basic' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'qualification_dbs_enhanced'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'qualification_dbs_enhanced_barred'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced Barred List' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if key == 'no_qualification_dbs'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == false || prs.dbs_issue_date == null || prs.dbs_issue_date < twoYearsOld
        else if key == 'qualification_food_health_2'
          prs.food_health_level_two_qualification == true
        else if key == 'no_qualification_food_health_2'
          prs.food_health_level_two_qualification == false || prs.food_health_level_two_qualification == null
        else if key == 'c_19_tt'
          prs.has_c19_test == true
        else if key == 'no_c_19_tt'
          prs.has_c19_test == false || prs.has_c19_test == null
        else
          true
      team_size: (gr, val) =>
        prs = @findId('prospects', gr.prospect_id)
        if val == 'BIG'
          prs.big_teams == 'Yes'
        else if val == 'ALL'
          prs.all_teams == 'Yes'
        else if val == 'Bespoke'
          prs.bespoke == 'Yes'
        else
          false
      admin: (gr, key) =>
        gr[key] == true
      distance: (gr,dist_string) =>
        prs = @findId('prospects', gr.prospect_id)
        dist_values = dist_string.split(',')
        event_id = dist_values[0]
        min_dist = dist_values[1]
        max_dist = dist_values[2]
        event = @findId('events', event_id)
        if (coord1 = coordinatesForRecord(prs)) && (coord2 = coordinatesForRecord(event))
          dist = distanceBetweenPointsInMiles(coord1, coord2)
          (dist >= min_dist) and (dist < max_dist)
        else
          false
      is_best: (gr, value) =>
        if value == 'true'
          gr.is_best == true
        else if value == 'false'
          gr.is_best == false
      avg_rating: (gr, rating) =>
        prs = @findId('prospects', gr.prospect_id)
        if rating == 'None' && !prs.avg_rating
          true
        else
          prs.avg_rating >= rating

    )

    @addFilters('interview_blocks',
      current: (block,flag) =>
        (block.date.getTime() >= getToday().getTime()) == flag
    )

    @addFilters('interview_slots',
      open: (slot,flag) =>
        max_applicants = @findId('interview_blocks', slot.interview_block_id).number_of_applicants_per_slot
        (slot.interviews_count < max_applicants) == flag
      date: (slot, date) =>
        ib_date = @findId('interview_blocks', slot.interview_block_id).date
        ib_date.getTime() == date.getTime()
      bulk_interview_id: (slot, bulk_interview_id) =>
        bid = @findId('interview_blocks', slot.interview_block_id).bulk_interview_id
        bid == bulk_interview_id
    )

    @addFilters('invoices',
      search_client: (invoice,val) =>
        client = @findId('clients', @findId('event_clients', invoice.event_client_id).client_id)
        matchStringStart(client.name, val)
      search_event: (invoice,val) =>
        event = @findId('events', @findId('event_clients', invoice.event_client_id).event_id)
        matchStringStart(event.name, val)
      tax_year_id: (invoice, val) =>
        @findId('tax_weeks', invoice.tax_week_id).tax_year_id == parseInt(val)
      tax_week_id: (invoice, val) =>
        invoice.tax_week_id == parseInt(val)
    )

    @addFilters('officers',
      locked_out: (officer, flag) =>
        officer.locked_out == (flag == 'true')
      role: (officer, val) =>
        (val == '') ||
        (val == 'Active' && officer.role != 'archived') ||
        (val == officer.role)
      active_operational_officer: (officer, flag) =>
        (!officer.role == 'archived' && officer.active_operational_officer) == (flag == true)
    )

    @addFilters('pay_weeks',
      status: (pw, val) =>
        if(val.constructor == Array)
          val.indexOf(pw.status) >= 0
        else
          pw.status == val
      tax_year_id: (pw, val) =>
        @findId('tax_years', @findId('tax_weeks', pw.tax_week_id).tax_year_id).id == val
      tax_week_id: (pw,val) =>
        pw.tax_week_id == parseInt(val)
      event_id: (pw,val) =>
        pw.event_id == parseInt(val)
      job_id: (pw,val) =>
        val = parseInt(val, 10)
        if((pw.job_id == null) && (val < 0)) then true else pw.job_id == val
      search: (pw, search) =>
        if search && search.match(/\S/) # must have at least 1 non-whitespace char
          search = search.split(/\s+/).map((word) => new RegExp(word.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'i'))
          result = search.every((regex) =>
            prospect = @findId('prospects', pw.prospect_id)
            prospect && prospect.last_name && prospect.first_name &&
              (prospect.last_name.match(regex) || prospect.first_name.match(regex)))
        else
          true
    )

    @addFilters('prospects',
      patterns: (prs, value) =>
        if value == 'weekdays'
          prs.week_days_work == true
        else if value == 'weekends'
          prs.weekends_work == true
        else if value == 'day'
          prs.day_shifts_work == true
        else
          prs.evening_shifts_work == true
      coms: (prs, value) =>
        if value == 'email'
          prs.contact_via_email == true
        else if value == 'tele'
          prs.contact_via_telephone == true
        else if value == 'text'
          prs.contact_via_text == true
        else
          prs.contact_via_whatsapp == true
      prospect_skills: (prs, skill) =>
        skillTypes = ['NONE', 'SOME', 'MEDIUM', 'HIGH']
        if skill == 'has_sports'
          prs.sport_skill in skillTypes
        else if skill == 'has_bar'
          prs.bar_skill in skillTypes
        else if skill == 'has_promotional'
          prs.promo_skill in skillTypes
        else if skill == 'has_retail'
          prs.retail_skill in skillTypes
        else if skill == 'has_office'
          prs.office_skill in skillTypes
        else if skill == 'has_festivals'
          prs.festival_skill in skillTypes
        else if skill == 'bar_manager'
          prs.bar_manager_skill == true
        else if skill == 'staff_leadership'
          prs.staff_leader_skill == true
        else if skill == 'has_hospitality'
          prs.hospitality_skill in skillTypes
        else if skill == 'has_warehouse'
          prs.warehouse_skill in skillTypes
      prospect_marketing: (prs, skill) =>
        if skill == 'has_sports'
          prs.has_sport_and_outdoor == true
        else if skill == 'has_bar'
          prs.has_bar_and_hospitality == true
        else if skill == 'has_promotional'
          prs.has_promotional_and_street_marketing == true
        else if skill == 'has_retail'
          prs.has_merchandise_and_retail == true
        else if skill == 'has_office'
          prs.has_reception_and_office_admin == true
        else if skill == 'has_festivals'
          prs.has_festivals_and_concerts == true
        else if skill == 'bar_manager'
          prs.has_bar_management_experience == true
        else if skill == 'staff_leadership'
          prs.has_staff_leadership_experience == true
        else if skill == 'festival_event_bar_management'
          prs.has_festival_event_bar_management_experience == true
        else if skill == 'event_production'
          prs.has_event_production_experience == true
        else if skill == 'has_hospitality'
          prs.has_hospitality_marketing == true
        else if skill == 'has_warehouse'
          prs.has_warehouse_marketing == true
      active_applicant: (prs, month) =>
        starOfMonth = new Date((new Date).getFullYear(), (new Date).getMonth(), 1);
        if month == 'THIS_MONTH'
          prs.created_at  >= starOfMonth
        else if month == 'LAST_MONTH'
          lastMonth = getToday()
          lastMonth.setMonth(lastMonth.getMonth() - 1)
          starOfLastMonth = new Date(lastMonth.getFullYear(), lastMonth.getMonth(), 1);
          prs.created_at  >= starOfLastMonth && prs.created_at < starOfMonth
      interview_type: (prs, type) =>
        if type == 'Call'
          prs.telephone_call_interview == true
        else if type == 'Video'
          prs.video_call_interview == true
      selected_team: (prs,flag) =>
        isSelected('team', prs.id) == (flag == 'true')
      team_size: (prs, val) =>
        if val == 'BIG'
          prs.big_teams == 'Yes'
        else if val == 'ALL'
          prs.all_teams == 'Yes'
        else if val == 'Bespoke'
          prs.bespoke == 'Yes'
        else
          false
      selected: (prs,flag) =>
        isSelected('applicants', prs.id) == (flag == 'true')
      search_email: (prs,val) =>
        prs.email.indexOf(val.trim()) != -1 ||
          (prs.mobile_no      && prs.mobile_no.indexOf(val.trim()) != -1) ||
          (prs.home_no        && prs.home_no.indexOf(val.trim()) != -1)
      registered_in: (prs,days) =>
        today = getToday()
        ms = parseInt(days,10) * 24 * 60 * 60 * 1000
        if ms > 0
          #Positive: Registered in 'ms' days or greater
          (today - prs.registered) >= ms
        else
          #Negative: Registered in 'ms' days or less
          (today - prs.registered) <= Math.abs(ms)
      requested_event: (prs,event_id) =>
        if @Index == 0 && event_id == 'ANY'
          @event_ids = (x.id for x in @queryAll('events', {active: true}))
          @Index = 1
        else if @Index != 0 && event_id != 'ANY'
          @Index = 0
        if event_id == 'ANY'
          questionnaire = @lookupTable('questionnaires', 'prospect_id')[prs.id]
          requests = @lookupTable('gig_requests', 'prospect_id')[prs.id]
          requests?.some((gr) => gr.event_id in @event_ids)
        else
          event_id = parseInt(event_id,10)
          requests = @lookupTable('gig_requests', 'prospect_id')[prs.id]
          requests?.some((gr) => !gr.gig_id? && gr.event_id == event_id)
      unrequested_event: (prs,event_id) =>
        if @Index == 0 && event_id == 'ANY'
          @event_ids = (x.id for x in @queryAll('events', {active: true}))
          @Index = 1
        else if @Index != 0 && event_id != 'ANY'
          @Index = 0
        if event_id == 'ANY'
          questionnaire = @lookupTable('questionnaires', 'prospect_id')[prs.id]
          requests = @lookupTable('gig_requests', 'prospect_id')[prs.id]
          !(requests?.some((gr) => !gr.gig_id? && gr.event_id in @event_ids) && questionnaire?.some((qn) => qn.enjoy_working_on_team != null && qn.enjoy_working_on_team == true  || qn.interested_in_bar != null && qn.interested_in_bar == true || qn.promotions_experience != null && qn.promotions_experience == true || qn.team_leader_experience != null && qn.team_leader_experience == true || qn.retail_experience != null && qn.retail_experience == true || qn.interested_in_marshal != null && qn.interested_in_marshal == true))
        else
          event_id = parseInt(event_id,10)
          requests = @lookupTable('gig_requests', 'prospect_id')[prs.id]
          !(requests?.some((gr) => !gr.gig_id? && gr.event_id == event_id))
      distance: (prs,dist_string) =>
        dist_values = dist_string.split(',')
        event_id = dist_values[0]
        min_dist = dist_values[1]
        max_dist = dist_values[2]
        event = @findId('events', event_id)
        if (coord1 = coordinatesForRecord(prs)) && (coord2 = coordinatesForRecord(event))
          dist = distanceBetweenPointsInMiles(coord1, coord2)
          (dist >= min_dist) and (dist < max_dist)
        else
          false
      bulk_interview_id_and_date: (prs, val) =>
        #parseInt will grab only the 'id' from the string. Negative Number == 'None'
        if (parseInt(val, 10) < 0)
          prs.bulk_interview_id_and_date == undefined
        else
          prs.bulk_interview_id_and_date == val
      interview_slot_id:(prs,id) =>
        # old code
        # prs.interview_slot_id == parseInt(id, 10)
        interview = @findId('interviews', prs.interview_id)
        check = ""
        if interview
          check = interview.time_type + "." + interview.interview_block_id
        check == id
      preferred_type:(prs, type) =>
        (((type == 'Phone'    || type == 'Online') && prs.prefers_phone) ||
          ((type == 'Skype'    || type == 'Online') && prs.prefers_skype) ||
          ((type == 'Facetime' || type == 'Online') && prs.prefers_facetime) ||
          ((type == 'In Person'                     && prs.prefers_in_person)))
      preferred_time:(prs, time) =>
        ((time == 'Morning'       && prs.prefers_morning) ||
          (time == 'Afternoon'     && prs.prefers_afternoon) ||
          (time == 'Early Evening' && prs.prefers_early_evening) ||
          (time == 'Midweek'       && prs.prefers_midweek) ||
          (time == 'Weekend'       && prs.prefers_weekend))
          id:           (prs,val) =>
        prs.id == parseInt(val,10)
      search_email: (prs,val) =>
        prs.email.indexOf(val.trim()) != -1 ||
          (prs.mobile_no      && prs.mobile_no.indexOf(val.trim()) != -1) ||
          (prs.home_no        && prs.home_no.indexOf(val.trim()) != -1)
      has_gig_requests: (prs,flag) =>
        if flag == 'REQUESTS'
          prs.has_gig_requests?
        else if flag == 'SPARE'
          prs.has_spare_gig_requests?
        else
          true
      age: (prs,val) =>
        return false unless prs.age
        predicate = {'>=21':((age) => age >= 21), '>=18':((age) => age >= 18), '<21': ((age) => age < 21), '<18': ((age) => age < 18)}
        predicate[val](prs.age)
      no_id: (prs, val) =>
        (!prs.id_number? || !prs.id_type || !prs.id_sighted || (prs.id_type == 'Pass Visa' && !prs.visa_number?) || (prs.id_type == 'Work/Residency Visa' && !prs.share_code? && !prs.visa_number?) || (prs.visa_expiry && (prs.visa_expiry < new Date))) == val
      completed_training: (prs, training_type) =>
        if training_type == 'NONE'
          !(prs['training_ethics'] || prs['training_customer_service'] || prs['training_sports'] || prs['training_bar_hospitality'] || prs['training_health_safety'])
        else if training_type == 'M' || training_type == 'F'
          prs.gender == training_type
        else if training_type.substring(0,3) == 'NO-'
          !prs[training_type.substring(3,training_type.length)]
        else if training_type == 'M' || training_type == 'F'
          prs.gender == training_type
        else
          prs[training_type]
      active_team: (prs, value) =>
        if value == 'Y'
          sixMonthBefore = getToday()
          sixMonthBefore.setMonth(sixMonthBefore.getMonth() - 1)
          prs.last_login >= sixMonthBefore
        else if value == 'N'
          sixMonthBefore = getToday()
          sixMonthBefore.setMonth(sixMonthBefore.getMonth() - 1)
          !(prs.last_login >= sixMonthBefore)
      fact_team: (prs, val) =>
        if val == 'qualification_dbs_basic'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Basic' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'qualification_dbs_enhanced'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'qualification_dbs_enhanced_barred'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == true && prs.dbs_qualification_type == 'Enhanced Barred List' && prs.dbs_issue_date != null && prs.dbs_issue_date >= twoYearsOld
        else if val == 'no_qualification_dbs'
          twoYearsOld = getToday()
          twoYearsOld.setFullYear(twoYearsOld.getFullYear() - 2)
          prs.dbs_qualification == false || prs.dbs_issue_date == null || prs.dbs_issue_date < twoYearsOld
        else if val == 'qualification_food_health_2'
          prs.food_health_level_two_qualification == true
        else if val == 'no_qualification_food_health_2'
          prs.food_health_level_two_qualification == false || prs.food_health_level_two_qualification == null
        else if val == 'c_19_tt'
          prs.has_c19_test == true
        else if val == 'no_c_19_tt'
          prs.has_c19_test == false || prs.has_c19_test == null
        else
          prs.bar_license_type == val
      team_view_admin: (prs, flag) =>
        if flag == 'id_true' || flag == 'id_false'
          if flag == 'id_true'
            flag = 'true'
          else if flag == 'id_false'
            flag = 'false'
          (prs.id_number? && prs.id_type? && prs.id_sighted? && (prs.id_type != 'Pass Visa' || prs.visa_number?) && (prs.id_type != 'Work/Residency Visa' || prs.share_code? || prs.visa_number?) && (!prs.visa_expiry? || (prs.visa_expiry >= new Date))) == (flag == 'true')
        else if flag == 'tax_true' || flag == 'tax_false'
          if flag == 'tax_true'
            flag = 'true'
          else if flag == 'tax_false'
            flag = 'false'
          prs.tax_choice? == (flag == 'true')
        else if flag == 'bank_true' || flag == 'bank_false'
          if flag == 'bank_true'
            flag = 'true'
          else if flag == 'bank_false'
            flag = 'false'
          (prs.bank_account_name? && prs.bank_sort_code? && prs.bank_account_no?) == (flag == 'true')
        else if flag == 'ni_true' || flag == 'ni_false'
          if flag == 'ni_true'
            flag = 'true'
          else if flag == 'ni_false'
            flag = 'false'
          prs.ni_number? == (flag == 'true')
        else if flag == 'LARGE' || flag == 'true' || flag == 'false'
          if flag == 'LARGE'
            prs.photo != null && prs.has_large_photo
          else
            (prs.photo != null) == (flag == 'true')


      has_id: (prs, flag) =>
        (prs.id_number? && prs.id_type? && prs.id_sighted? && (prs.id_type != 'Pass Visa' || prs.visa_number?) && (prs.id_type != 'Work/Residency Visa' || prs.share_code? || prs.visa_number?) && (!prs.visa_expiry? || (prs.visa_expiry >= new Date))) == (flag == 'true')
      has_tax_choice: (prs, flag) =>
        prs.tax_choice? == (flag == 'true')
      no_bank: (prs, val) =>
        (!prs.bank_account_name? || !prs.bank_sort_code? || !prs.bank_account_no?) == val
      has_bank_info: (prs, flag) =>
        (prs.bank_account_name? && prs.bank_sort_code? && prs.bank_account_no?) == (flag == 'true')
      has_ni: (prs, flag) =>
        prs.ni_number? == (flag == 'true')
      is_live: (prs,flag) =>
        prs.is_live == (flag == 'true')
      manager_level: (prs,val) =>
        prs.manager_level == val
      has_photo: (prs,val) =>
        if val == 'LARGE'
          prs.photo != null && prs.has_large_photo
        else
          (prs.photo != null) == (val == 'true')
      gig: (prs,event_id) =>
        event_id = parseInt(event_id, 10)
        gigs = @lookupTable('gigs', 'prospect_id')[prs.id]
        gigs?.some((g) => g.event_id == event_id)
      no_gig: (prs,event_id) =>
        event_id = parseInt(event_id,10)
        gigs = @lookupTable('gigs', 'prospect_id')[prs.id]
        requests = @lookupTable('gig_requests', 'prospect_id')[prs.id]
        !(requests?.some((gr) => gr.event_id == event_id)) && !(gigs?.some((g) => g.event_id == event_id))
      avg_rating: (prs, rating) =>
        if rating == 'None' && !prs.avg_rating
          true
        else
          prs.avg_rating >= rating
      payroll_status: (prs, status) =>
        if status == 'THIS_WEEK'
          prs.has_assignments_last_week
        else if status == 'NEXT_WEEK'
          prs.has_assignments_this_week
        else if status == 'THIS_OR_NEXT_WEEK'
          prs.has_assignments_last_week || prs.has_assignments_this_week
        else
          false
      qualifications: (prs, key) =>
        #console.log "addFilters prospects -> qualifications ?"
        prs[key]
      region_name: (prs,val) =>
        regionForRecord(prs) == val
      active_in_year: (prs,val) =>
        today = getToday()
        thisYear = today.getFullYear()
        if val == 'THIS_YEAR'
          prs.has_gig_request_in_year[thisYear] || prs.has_gig_in_year[thisYear]
        else if val == 'LAST_YEAR'
          prs.has_gig_request_in_year[thisYear-1] || prs.has_gig_in_year[thisYear-1]
        else if val == 'THIS_OR_LAST_YEAR'
          prs.has_gig_request_in_year[thisYear] || prs.has_gig_request_in_year[thisYear-1] || prs.has_gig_in_year[thisYear] || prs.has_gig_in_year[thisYear-1]
        else
          false
      created_this_year: (prs, val) =>
        today = getToday()
        thisYear = today.getFullYear()
        if val == true
          if prs.created_at != null
            prs.created_at.getFullYear() == parseInt(thisYear,10)

      last_login: (prs,val) =>
        compareDate = getToday()
        if val == 'LT_6_MONTHS'
          compareDate.setMonth(compareDate.getMonth() - 6)
          return prs.last_login >= compareDate
        else if val == 'LT_12_MONTHS'
          compareDate.setMonth(compareDate.getMonth() - 12)
          return prs.last_login >= compareDate
        else
          false
    )

    @addFilters('shifts',
      tax_week_id: (shift, tax_week_id) =>
        shift.tax_week_id == parseInt(tax_week_id)
      date: (shift, date) =>
        shift.date.getTime() == date.getTime()
    )

    @addFilters('tax_weeks',
      includes_date: (tw, date) =>
        dateInRange(date, tw.date_start, tw.date_end)
      overlaps_dates: (tw, dates) =>
        dates.sort(date_sort_asc)
        (tw.date_start.getTime() <= dates[1].getTime() && dates[0].getTime() <= tw.date_end.getTime())
      current: (tw, val) =>
        currentTime = new Date()
        currentTime.setDate(currentTime.getDate()-21)
        (tw.date_start > currentTime) == val
      has_active_events: (tw, flag) =>
        (tw.active_events.length > 0) == flag
      has_pending_events: (tw, flag) =>
        (tw.pending_events.length > 0) == flag
      has_to_approve_events: (tw, flag) =>
        (tw.to_approve_events.length > 0) == flag
    )

    @addFilters('tax_years',
      includes_date: (ty, date) =>
        dateInRange(date, ty.date_start, ty.date_end)
      overlaps_dates: (ty, dates) =>
        dates.sort(date_sort_asc)
        (ty.date_start <= dates[1] && dates[0] <= ty.date_end)
    )

    @addFilters('timesheet_entries',
      status: (tse, val) =>
        if(val.constructor == Array)
          val.indexOf(tse.status) >= 0
        else
          tse.status == val
      tax_year_id: (tse, val) =>
        @findId('tax_years', @findId('tax_weeks', tse.tax_week_id).tax_year_id).id == val
      tax_week_id: (tse,val) =>
        tse.tax_week_id == parseInt(val)
      event_id: (tse,val) =>
        @findId('gigs', @findId('gig_assignments', tse.gig_assignment_id).gig_id).event_id == parseInt(val)
      search: (tse, search) =>
        if search && search.match(/\S/) # must have at least 1 non-whitespace char
          search = search.split(/\s+/).map((word) => new RegExp(word.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'i'))
          result = search.every((regex) =>
            prospect = @findId('prospects', @findId('gigs', @findId('gig_assignments', tse.gig_assignment_id).gig_id).prospect_id)
            prospect && prospect.last_name && prospect.first_name &&
              (prospect.last_name.match(regex) || prospect.first_name.match(regex)))
        else
          true
      assignment: (tse, val) =>
        assignment = @findId('assignments', @findId('gig_assignments', tse.gig_assignment_id).assignment_id)
        if val.assignment_id?
          assignment.id == val.assignment_id
        else if !(val.job_id?) && !(val.location_id?) && !(val.shift_id) && !(val.date)
          true
        else
          @filterShiftLocationJobDateMatch(assignment, val)
      time_clock_report_id: (tse, val) =>
        tse.time_clock_report_id == parseInt(val)
    )

  filterShiftLocationJobDateMatch: (assignment, val) ->
    job = @findId('jobs', assignment.job_id)
    if !(val.job_id?) || job.id == val.job_id
      job_matches = true
    location = @findId('locations', assignment.location_id)
    if !(val.location_id?) || location.id == val.location_id
      location_matches = true
    shift = @findId('shifts', assignment.shift_id)
    if (!val.shift_id?) || shift.id == val.shift_id
      shift_matches = true
    if (!val.date?) || shift.date.getTime() == val.date.getTime()
      date_matches = true
    job_matches && location_matches && shift_matches && date_matches

# export to global scope
window.DbProxy = DbProxy
