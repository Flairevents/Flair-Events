class TestEventsTab < Flair::Test::Browser::Suite
  extend  Flair::Test::Browser::Forms
  include Flair::Test::Browser::OfficeZone

  start_by 'add some records to DB' do
    db[:clients].insert_with_tstamps(name: 'Client 1')
    db[:clients].insert_with_tstamps(name: 'Client 2')
    db[:clients].insert_with_tstamps(name: 'Client 3')

    id1 = db[:clients].where(name: 'Client 1').get(:id)
    db[:client_contacts].insert_with_tstamps(client_id: id1, first_name: 'Firsty',
      last_name: 'Lasty', email: 'email@mail.com', mobile_no: '12345')
  end

  _then 'log into Office Zone' do
    login_to_office_zone_as_manager
  end

  _then 'select Events tab' do
    tabs.find('a', text: 'Events').click
    tabs.find('.active').text.must == 'Events'
    events_pane.must.match_selector('.active')
  end

  ##############################################################################
    def new_button
      @new_button ||= events_pane.find_button(text: 'New')
    end

    def new_event_form
      @new_form ||= events_pane.find('form#new_event', visible: false)
    end

    def click_new_event_link
      link = if_not_visible(events_pane, 'a.command-link', text: 'Event') do
        new_button.click
      end
      link.click
      new_event_form.must.be_visible
    end
  ##############################################################################

  _then "click on 'New Event' to open sliding form" do
    click_new_event_link
  end

  ##############################################################################
    def_form_input_methods 'new_event', 'new_event_form', 'event',
      %w{name display_name date_start date_end}

    def new_event_clients_select
      # using the <select> element doesn't work
      # Selenium says that it is covered and can't receive clicks
      @new_event_clients_select ||= new_event_form.find('span.select2-selection')
    end

    def save_new_event
      @save_new_link ||= events_pane.find('div.record-new a.save')
      @save_new_link.click
      # find(..., visible: false) gets BOTH visible and invisible elements
      page.find('.saving-changes', visible: false).must_not.be_visible
    end

    def close_new_event
      @close_new_link ||= events_pane.find('div.record-new a.close')
      @close_new_link.click
      new_event_form.must_not.be_visible
      page.find('.flash', visible: false).must_not.be_visible
    end

    def close_edit_event
      @close_edit_link ||= events_pane.find('div.record-edit a.close')
      @close_edit_link.click
      page.find('.flash', visible: false).must_not.be_visible
    end

    def flash
      @flash ||= find('.flash', visible: false)
    end
  ##############################################################################

  _then 'fill in basic Event details and save' do
    # Fill in names
    new_event_name_input.send_keys('Test Event 1')
    new_event_display_name_input.send_keys('Test Event 1!!!')
    # Fill in dates
    new_event_date_start_input.click
    datepicker.must.be_visible
    datepicker.first('td', text: /^1$/).click # any month and year
    new_event_date_end_input.send_keys("10/01/#{Date.today.year + 1}\n")
    # Choose a client
    new_event_clients_select.click
    page.find('li.select2-results__option', text: 'Client 1').click
    save_new_event
    # When new record is saved, 'new' form automatically hides and 'edit' form
    #   appears instead
    close_edit_event
    # Check if record is in DB
    db[:events].where(name: 'Test Event 1').count.must == 1
  end

  _then 'check that Public Start and End Dates were automatically set' do
    record = db[:events].where(name: 'Test Event 1').first
    record[:public_date_start].must == record[:date_start]
    record[:public_date_end].must   == record[:date_end]
  end

  _then 'create another new Event, but double-click to close sliding form' do
    # record should be auto-saved when closing sliding form
    click_new_event_link
    new_event_name_input.send_keys('Test Event 2')
    new_event_display_name_input.send_keys('Test Event 2!!')
    new_event_date_start_input.send_keys("5/2/#{Date.today.year + 1}\n")
    new_event_date_end_input.send_keys("8/2/#{Date.today.year + 1}\n")
    # Try choosing multiple clients
    new_event_clients_select.click
    page.find('li.select2-results__option', text: 'Client 2').click
    new_event_clients_select.click
    page.find('li.select2-results__option', text: 'Client 3').click
    # double-click on empty space to save
    # this will go on the very top-left pixel of the form, missing the fields
    new_event_form.first('span').double_click
    # find(..., visible: false) gets BOTH visible and invisible elements
    page.find('.saving-changes', visible: false).must_not.be_visible
    page.find('.flash', visible: false).must_not.be_visible
    # Check if record is in DB
    ids = db[:events].where(name: 'Test Event 2').all.map { |r| r[:id] }
    ids.count.must == 1
    # Check that it really has 2 Clients
    db[:event_clients].where(event_id: ids[0]).count.must == 2
  end

  ##############################################################################
    def flash_must_display(message)
      flash.must.be_visible
      if message.is_a?(Regexp)
        flash.text.must =~ message
      else
        flash.text.must == message
      end
      flash.click
      flash.must_not.be_visible
    end
  ##############################################################################

  _then "leave Clients unfilled and try to save" do
    click_new_event_link

    new_event_name_input.send_keys('Test Event 3')
    new_event_display_name_input.send_keys('Test Event 3!')
    new_event_date_start_input.send_keys("5/2/#{Date.today.year + 1}\n")
    new_event_date_end_input.send_keys("8/2/#{Date.today.year + 1}\n")

    save_new_event
    flash_must_display('Must Specify a Client')

    # fill in the client again
    new_event_clients_select.click
    page.find('li.select2-results__option', text: 'Client 3').click
  end

  _then "leave Internal Event Name unfilled and try to save" do
    new_event_name_input.fill_in(with: '')
    save_new_event
    flash_must_display("and Name can't be blank") # grammar was never our strong suit

    new_event_name_input.fill_in(with: 'Test Event 3')
  end

  _then "try to use duplicate Internal Event Name" do
    new_event_name_input.fill_in(with: 'Test Event 1')
    save_new_event
    flash_must_display("and Name has already been taken")

    new_event_name_input.fill_in(with: 'Test Event 3')
  end

  _then "leave Public Event Name unfilled and try to save" do
    new_event_display_name_input.fill_in(with: '')
    save_new_event
    flash_must_display("and Display name can't be blank")

    new_event_display_name_input.fill_in(with: 'Test Event 3!')
  end

  _then "leave Start Date unfilled and try to save" do
    new_event_date_start_input.fill_in(with: '')
    save_new_event
    flash_must_display("and Start Date can't be blank")

    new_event_date_start_input.fill_in(with: "5/2/#{Date.today.year + 1}\n")
  end

  _then "leave End Date unfilled and try to save" do
    new_event_date_end_input.fill_in(with: '')
    save_new_event
    flash_must_display("and End Date can't be blank")
  end

  _then "click on 'Cancel' button and form closes" do
    events_pane.find('a.cancel').click
    new_event_form.must_not.be_visible
    # values in form must be cleared when Cancel is clicked
    new_event_name_input.text.must.be_empty
  end

  ##############################################################################
    def event_list
      @event_list ||= events_pane.first('#events-list')
    end

    def edit_event_form
      @edit_form ||= events_pane.find('form#edit_event', visible: false)
    end

    def_form_input_methods 'edit_event', 'edit_event_form', 'event',
      %w{category_id paid_breaks show_in_public show_in_history staff_needed
         public_date_start public_date_end date_callback_due show_in_home
         show_in_payroll show_in_time_clocking_app site_manager office_manager
         address post_code location website jobs_description blurb_title
         date_start date_end blurb_subtitle blurb_opening blurb_job blurb_shift
         blurb_wage_additional blurb_uniform blurb_transport blurb_closing
         notes require_training_ethics require_training_customer_service
         require_training_sports require_training_bar_hospitality
         require_training_health_safety name display_name}

    def save_edited_event
      @save_edited_link ||= events_pane.find('div.record-edit a.save')
      @save_edited_link.click
      page.find('.saving-changes', visible: false).must_not.be_visible
    end
  ##############################################################################

  _then 'double-click on record in Events list to edit' do
    event_list.find('td', text: 'Test Event 1').double_click
    edit_event_form.must.be_visible
  end

  _then 'check that no-one is hired yet' do
    edit_event_form.find('#edit_event_gigs_count').text.must == '0'
  end

  _then 'try an incorrect post code' do
    edit_event_post_code_input.fill_in(with: 'AAA111')
    save_edited_event
    flash_must_display(/Post code is invalid/)
    edit_event_post_code_input.fill_in(with: '')
  end

  _then 'try an incorrect web site' do
    edit_event_website_input.fill_in(with: 'htptpp;;/www-mysite-com')
    save_edited_event
    flash_must_display('Website is invalid')
    edit_event_website_input.fill_in(with: '')
  end

  _then 'try an invalid End Date' do
    end_date = edit_event_date_end_input.value
    # last year; this will definitely be before the start date
    edit_event_date_end_input.fill_in(with: "10/1/#{Date.today.year - 1}")
    save_edited_event
    flash_must_display(/Start Date can't be after End Date/)
    edit_event_date_end_input.fill_in(with: end_date)
  end

  _then 'try an invalid Public End Date' do
    end_date = edit_event_public_date_end_input.value
    # last year; this will definitely be before the start date
    edit_event_public_date_end_input.fill_in(with: "10/1/#{Date.today.year - 1}")
    save_edited_event
    flash_must_display(/Public Start Date can't be after Public End Date/)
    edit_event_public_date_end_input.fill_in(with: end_date)
  end

  _then 'try negative Staff Needed' do
    edit_event_staff_needed_input.fill_in(with: '-10')
    save_edited_event
    flash_must_display('Staff needed must be greater than or equal to 0')
  end

  ##############################################################################
    def event_categories
      Hash[db[:event_categories].map { |ec| [ec[:name], ec]}]
    end
  ##############################################################################

  _then 'fill in all fields correctly and save' do
    edit_event_category_id_input.select('Festival')
    edit_event_paid_breaks_input.set(true)
    edit_event_show_in_public_input.set(false)
    edit_event_show_in_history_input.set(false)
    edit_event_staff_needed_input.fill_in(with: '10')

    # Fill in Start Date and End Date at the same time as Public Dates
    # Because Public Dates are 'clamped' within range set by Start/End Dates
    edit_event_date_start_input.fill_in(with: "1/5/#{Date.today.year + 1}")
    edit_event_public_date_start_input.fill_in(with: "1/5/#{Date.today.year + 1}")
    edit_event_date_end_input.fill_in(with: "10/5/#{Date.today.year + 1}")
    edit_event_public_date_end_input.fill_in(with: "10/5/#{Date.today.year + 1}")
    edit_event_date_callback_due_input.fill_in(with: "3/10/#{Date.today.year + 1}")
    edit_event_show_in_home_input.set(false)
    edit_event_show_in_payroll_input.set(false)
    edit_event_show_in_time_clocking_app_input.set(true)
    edit_event_site_manager_input.fill_in(with: 'Fluffy Duck')
    edit_event_office_manager_input.fill_in(with: 'Fluffy Cat')
    edit_event_address_input.fill_in(with: "72 High Street, Ipswich") # 100km from London
    edit_event_post_code_input.fill_in(with: 'AB10 1XZ') # in Scotland...
    edit_event_location_input.fill_in(with: 'Somewhere')
    edit_event_website_input.fill_in(with: 'http://google.com')
    edit_event_jobs_description_input.fill_in(with: 'Good and fine')
    edit_event_blurb_title_input.fill_in(with: 'A Great Event')
    edit_event_blurb_subtitle_input.fill_in(with: '...for Great People')
    edit_event_blurb_opening_input.fill_in(with: 'Look at this!')
    edit_event_blurb_job_input.fill_in(with: 'Great jobs')
    edit_event_blurb_shift_input.fill_in(with: 'Great shifts')
    edit_event_blurb_wage_additional_input.fill_in(with: 'Cash money $$$')
    edit_event_blurb_uniform_input.fill_in(with: 'Great uniforms')
    edit_event_blurb_transport_input.fill_in(with: 'Great transport')
    edit_event_blurb_closing_input.fill_in(with: 'Apply now!')

    edit_event_notes_input.fill_in(with: 'Other notes') # this field is comically small

    edit_event_require_training_ethics_input.set(true)
    edit_event_require_training_sports_input.set(true)
    edit_event_require_training_customer_service_input.set(true)
    edit_event_require_training_bar_hospitality_input.set(true)
    # NOTE: this checkbox is currently disabled
    # edit_event_require_training_health_safety_input.set(true)

    save_edited_event
    page.find('.flash', visible: false).must_not.be_visible

    record = db[:events].where(name: 'Test Event 1').first
    record[:category_id].must == event_categories['Festival'][:id]
    record[:paid_breaks].must == true
    record[:show_in_public].must == false
    record[:show_in_history].must == false
    record[:staff_needed].must == 10

    record[:public_date_start].must == Date.new(Date.today.year+1, 5, 1)
    record[:public_date_end].must   == Date.new(Date.today.year+1, 5, 10)
    record[:date_callback_due].must == Date.new(Date.today.year+1, 10, 3)

    record[:show_in_home].must == false
    record[:show_in_payroll].must == false
    record[:show_in_time_clocking_app].must == true

    record[:site_manager].must == 'Fluffy Duck'
    record[:office_manager].must == 'Fluffy Cat'
    record[:address].must == "72 High Street, Ipswich"
    record[:post_code].must == 'AB10 1XZ'
    record[:location].must == 'Somewhere'
    record[:website].must == 'google.com'
    record[:jobs_description].must == 'Good and fine'

    record[:blurb_title].must == 'A Great Event'
    record[:blurb_subtitle].must == '...for Great People'
    record[:blurb_opening].must == 'Look at this!'
    record[:blurb_job].must == 'Great jobs'
    record[:blurb_shift].must == 'Great shifts'
    record[:blurb_wage_additional].must == 'Cash money $$$'
    record[:blurb_uniform].must == 'Great uniforms'
    record[:blurb_transport].must == 'Great transport'
    record[:blurb_closing].must == 'Apply now!'

    record[:notes].must == 'Other notes'

    record[:require_training_ethics].must == true
    record[:require_training_sports].must == true
    record[:require_training_customer_service].must == true
    record[:require_training_bar_hospitality].must == true
    # NOTE: this checkbox is currently disabled
    # record[:require_training_health_safety].must == true
  end

  ##############################################################################
    def edit_leaders_form
      @edit_leaders_form ||= events_pane.find('form#event-leaders-form', visible: false)
    end

    def_form_input_methods 'edit_leaders', 'edit_leaders_form', 'event',
      %w{leader_client_contact_id leader_general leader_meeting_location
         leader_meeting_location_coords leader_job_role leader_arrival_time
         leader_staff_job_roles leader_energy leader_uniform leader_handbooks
         leader_food leader_staff_arrival leader_transport leader_accomodation}
  ##############################################################################

  _then 'fill in Event Leader fields, and save' do
    find('#events a[href="#event-leaders"]').click
    edit_leaders_form.must.be_visible

    # pick client contact
    edit_leaders_leader_client_contact_id_input.select('Firsty Lasty')

    edit_leaders_leader_general_input.fill_in(with: 'Notes')
    edit_leaders_leader_meeting_location_input.fill_in(with: 'Location')
    edit_leaders_leader_meeting_location_coords_input.fill_in(with: '90,0')
    edit_leaders_leader_job_role_input.fill_in(with: 'Job Role')
    edit_leaders_leader_arrival_time_input.fill_in(with: 'Arrival Time')
    edit_leaders_leader_staff_job_roles_input.fill_in(with: 'Staff Job Roles')
    edit_leaders_leader_staff_arrival_input.fill_in(with: 'Staff Arrival')
    edit_leaders_leader_energy_input.fill_in(with: 'Energy')
    edit_leaders_leader_uniform_input.fill_in(with: 'Uniform')
    edit_leaders_leader_handbooks_input.fill_in(with: 'Handbooks')
    edit_leaders_leader_food_input.fill_in(with: 'Food')
    edit_leaders_leader_transport_input.fill_in(with: 'Transport')
    edit_leaders_leader_accomodation_input.fill_in(with: 'Accomodation')

    save_edited_event
    close_edit_event

    record = db[:events].where(name: 'Test Event 1').first

    record[:leader_client_contact_id].must == db[:client_contacts].where(first_name: 'Firsty', last_name: 'Lasty').get(:id)

    record[:leader_general].must == 'Notes'
    record[:leader_meeting_location].must == 'Location'
    record[:leader_meeting_location_coords].must =~ /^90,\s*0$/
    record[:leader_job_role].must == 'Job Role'
    record[:leader_arrival_time].must == 'Arrival Time'
    record[:leader_staff_job_roles].must == 'Staff Job Roles'
    record[:leader_staff_arrival].must == 'Staff Arrival'
    record[:leader_energy].must == 'Energy'
    record[:leader_uniform].must == 'Uniform'
    record[:leader_handbooks].must == 'Handbooks'
    record[:leader_food].must == 'Food'
    record[:leader_transport].must == 'Transport'
    record[:leader_accomodation].must == 'Accomodation'
  end

  ##############################################################################
    def edit_button
      @edit_button ||= events_pane.find_button(text: 'Edit')
    end
  ##############################################################################

  _then "highlight a different record and click 'Edit' button" do
    event_list.find('td', text: 'Test Event 2').click
    edit_button.click
    # Clicking the 'Edit' button should open the Edit form
    edit_event_form.must.be_visible
    edit_event_name_input.value.must == 'Test Event 2'
    close_edit_event
  end

# This is for testing 'live updates' when that feature is ready:
=begin
  _then 'when record is updated in DB, form (and events list) automatically reflect changes' do
    # first start editing the display name...
    edit_event_display_name_input.send_keys('!')
    # now update record on server side...
    db[:events].where(name: 'Test Event 2').update(name: 'TEST EVENT 2', display_name: 'TEST EVENT 2!')
    # client should automatically update...
    edit_event_name_input.value.must == 'TEST EVENT 2'
    event_list.must.match_selector('td', text: 'TEST EVENT 2')
    # but field which we already started editing should not change
    edit_event_display_name_input.text.must == 'Test Event 2!!!'
  end

  _then 'save form and fields which were edited will be saved' do
    save_edited_event
    page.find('.flash', visible: false).must_not.be_visible
    db[:events].where(name: 'TEST EVENT 2').get(:display_name).must == 'Test Event 2!!!'
  end

  _then 'create more records in DB and they automatically appear in Events list' do
    db[:events].insert_with_tstamps(name: 'Hospitality Event', display_name: 'Hospitality Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Hospitality'][:id])
    db[:events].insert_with_tstamps(name: 'Other Event', display_name: 'Other Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Other'][:id])
    db[:events].insert_with_tstamps(name: 'Promo Event', display_name: 'Promo Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Promo'][:id])
    db[:events].insert_with_tstamps(name: 'Sport Event', display_name: 'Sport Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Sport'][:id])
    db[:events].insert_with_tstamps(name: '2010 Event', display_name: '2010 Event',
      date_start: Date.new(2010,1,1), date_end: Date.new(2010,2,1), category_id: event_categories['Other'][:id])

    (5..20).each do |n|
      db[:events].insert_with_tstamps(name: "Event #{n}", display_name: "Event #{n}",
        date_start: Date.today+1, date_end: Date.today+3)
    end

    db[:events].insert_with_tstamps(name: 'Open Event', display_name: 'Open Event',
      date_start: Date.today+1, date_end: Date.today+3, status: 'OPEN', date_opened: Date.today)

    # more than 20 events have been created, but the page size is 20
    event_list.must.match_selector('tr.body-row', count: 20)
  end
=end

# Although the above tests will only work after 'live' updates are enabled, we still
#   need to create some records for the below tests...
  _then 'create more records in DB' do
    db[:events].insert_with_tstamps(name: 'Hospitality Event', display_name: 'Hospitality Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Hospitality'][:id],
      public_date_start: Date.today+1, public_date_end: Date.today+3)
    db[:events].insert_with_tstamps(name: 'Other Event', display_name: 'Other Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Other'][:id],
      public_date_start: Date.today+1, public_date_end: Date.today+3)
    db[:events].insert_with_tstamps(name: 'Promo Event', display_name: 'Promo Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Promo'][:id],
      public_date_start: Date.today+1, public_date_end: Date.today+3)
    db[:events].insert_with_tstamps(name: 'Sport Event', display_name: 'Sport Event',
      date_start: Date.today+1, date_end: Date.today+3, category_id: event_categories['Sport'][:id],
      public_date_start: Date.today+1, public_date_end: Date.today+3)
    db[:events].insert_with_tstamps(name: '2010 Event', display_name: '2010 Event',
      date_start: Date.new(2010,1,1), date_end: Date.new(2010,2,1), category_id: event_categories['Other'][:id],
      public_date_start: Date.new(2010,1,1), public_date_end: Date.new(2010,2,1))

    (5..20).each do |n|
      db[:events].insert_with_tstamps(name: "Event #{n}", display_name: "Event #{n}",
        date_start: Date.today+1, date_end: Date.today+3,
        public_date_start: Date.today+1, public_date_end: Date.today+3)
    end

    db[:events].insert_with_tstamps(name: 'Open Event', display_name: 'Open Event',
      date_start: Date.today+1, date_end: Date.today+3, status: 'OPEN', date_opened: Date.today,
      public_date_start: Date.today+1, public_date_end: Date.today+3)

    page.find('a.refresh-data').click
    page.find('.saving-changes', visible: false).must_not.be_visible
  end

  ##############################################################################
    def filter_bar
      @filter_bar ||= events_pane.find('#events-filter-bar')
    end

    def clear_filters_button
      @clear_filters_button ||= events_pane.find_button(text: 'Clear Filters')
    end
  ##############################################################################

  _then 'filter for Event name' do
    filter_bar.find('#search').fill_in(with: "Promo Event\n")
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Promo Event')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Event client' do
    filter_bar.find('#search_client').fill_in(with: "Client 2\n")
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Test Event 2')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Office Manager' do
    filter_bar.find('#search_office_manager').fill_in(with: "Fluff\n") # try partial search
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Test Event 1')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Category' do
    filter_bar.find('#category_id').select('Sport')
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Sport Event')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Year' do
    filter_bar.find('#event-year').select('2010')
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: '2010 Event')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Region' do
    filter_bar.find('#region_name').select('Scotland')
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Test Event 1')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'filter for Status' do
    filter_bar.find('#status').select('Open')
    # only one Event should match
    event_list.all('tr.body-row').size.must == 1
    event_list.must.have_selector('td', text: 'Open Event')
    # clear the filter for the next test...
    clear_filters_button.click
  end

  _then 'sort Events list by Name' do
    event_list.find('td.sorthdr', text: 'Name').click
    name_cells = event_list.all('span.event-name')
    (0..(name_cells.length-2)).each do |i|
      name_cells[i+1].text.must > name_cells[i].text
    end
  end

  ##############################################################################
    def pagination_controls
      @page_controls ||= events_pane.find('.pagination-controls')
    end
  ##############################################################################

  #_then 'go through pages of results' do
  #  pagination_controls.find('a.next-page').click
  #  name_cells = event_list.all('span.event-name')
  #  name_cells.size.must == 1
  #  name_cells[0].text.must == 'Test Event 2'
  #end

  _then 'sort Events list by Start Date' do
    event_list.find('td.sorthdr', text: 'Start').click
    # list should go back to 1st page
    pagination_controls.find('input.page-selector').value.must == '1'
    body_rows = event_list.all('tr.body-row')
    body_rows[0].text.must =~ /2010 Event/
  end

  _then 'sort Events by Region' do
    # Click twice to sort in reverse order -- otherwise all the nulls will come at the top
    event_list.find('td.sorthdr', text: 'Region').click.click
    body_rows = event_list.all('tr.body-row')
    body_rows[0].text.must =~ /Scotland/
  end

  _then 'sort Events by Category' do
    # The 'Category' column in on the far right and cannot be seen (and clicked)
    #   if the browser window is too small, so:
    page.current_window.maximize
    event_list.find('td.sorthdr', text: 'Category').click.click
    body_rows = event_list.all('tr.body-row')
    body_rows[0].text.must =~ /Sport/
  end

  ##############################################################################
    def delete_button
      @delete_button ||= events_pane.find_button(text: 'Delete')
    end
  ##############################################################################

  _then 'delete a new Event' do
    event_list.find('span.event-name', text: 'Test Event 1').click
    delete_button.must_not.match_selector('.disabled')
    delete_button.click
    # row must disappear
    event_list.must_not.have_selector('span.event-name', text: 'Test Event 1')
    # no spinner or anything appears while delete request is being processed, so it is hard to
    #   know when change is actually saved on server...
    try_assertion_repeatedly do
      db[:events].where(name: 'Test Event 1').count.must == 0
    end
  end

  # TODO: TEST EFFECTS OF CHANGING STATUS

  _then 'confirm we cannot delete completed Event' do

  end

  # what about bookings created automatically???
  _then 'create a new Booking' do

  end

  _then 'use Revert button' do

  end

  _then 'use Duplicate button' do

  end

  _then 'update Event Photo' do

  end

  # TODO: TEST MAP
end
