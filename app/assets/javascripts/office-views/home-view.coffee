class HomeView extends View
  constructor: (@last_month_applicants, @current_month_applicants, @active_people_last_year, @db, @viewport) ->
    super(@viewport)
    @db.onUpdate(['events', 'prospects', 'gigs', 'gig_requests'], => @redraw())
    @viewport.on('click', '.refresh-data', => @db.refreshData())

  draw: ->
    @viewport.html(JST['office_views/_home']({db: @db, last_month_applicants: @last_month_applicants, current_month_applicants: @current_month_applicants, active_people_last_year: @active_people_last_year}))
    $('[data-toggle=\'tooltip\']').tooltip()

window.HomeView = HomeView