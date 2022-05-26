require 'api_constraints'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'v2/public#home'

  match 'prospect_photo/:id', to: 'application#prospect_photo', via: :get
  match 'flag_photo/:id', to: 'application#flag_photo', via: :get
  match 'time_clock_report_signature/:id', to: 'application#time_clock_report_signature', via: :get
  match 'heartbeat', controller: 'application', via: :get
  match 'incoming_message', controller: 'application', via: [:get, :post]
  resources :quote_requests, only: [:create]
  ##### API
  namespace :api do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      match '/time_clocking/login', to: 'time_clocking#login', via: [:get, :post]
      match '/time_clocking/data', to: 'time_clocking#data', via: [:get, :post]
      match '/time_clocking/upload_report', to: 'time_clocking#upload_report', via: [:post]
      match 'log_error', to: 'api#log_error', via: [:post]
      match 'test_token', to: 'api#test_token', via: [:get, :post]
    end
    #scope module: :v2, constraints: ApiConstraints.new(version: 2, default: true) do
    #  resources :time_clocking
    #end
  end

  namespace :v2, path: '' do
    ##### Public Zone
    %w{workers onboard about join_us privacy registration_confirmation resend_confirmation case_studies}.each do |page|
      match page, to: 'public#'+page, as: page, via: :get
    end

    %w{events events_filter set_password add_category_events login contact contact_holding contact_submit register forgot_password style_guide}.each do |page|
      match page, to: 'public#'+page, as: page, via: [:get, :post]
    end

    get 'industries/:industry', to: 'public#industry', as: :industry
    get 'case_studies/:industry', to: 'public#case_studies', as: :case_industry

    ##### Client Zone
    match 'client', to: 'client#index', via: :get
    get 'hire' => 'client#login'
    %w[client_login activate set_password].each do |page|
      match "client/#{page}", to: 'client#'+page, via: [:get, :post]
    end

    ##### Quote
    post 'quote_request' => 'quote_requests#create'

    ##### Staff Zone
    match 'staff', to: 'staff#index', via: :get
    %w(
      cancel_interview
      check_if_logged_in
      check_email
      check_non_uk
      contact
      deactivate_account
      deselect_event
      events
      events_filter
      update_question_skills
      update_question_skills_sub
      get_hired_status
      get_non_eu_id_view
      get_training_module
      index
      library_item
      logout
      kid
      mark_training_module_complete
      reactivate_account
      refresh_contracts
      refresh_events
      refresh_online_interview_tab
      relogin
      seen_rejected_event
      select_event
      set_password
      sign_up_for_interview
      terms
      update_bank_details
      update_contact_preferences
      update_nationality
      update_personal_details
      update_questions
      update_tax_choice
      update_training_module_progress
      update_uk_id_type
      upload_birth_certificate
      upload_eu_passport
      upload_passport_and_visa
      update_share_code
      upload_photo
      upload_uk_birth_certificate
      upload_uk_passport
      upload_uk_passport_images
      unsubscribe
      change_new_employee_status
      induction_popup
    ).each do |action|
      match "staff/#{action}",     to: 'staff#'+action, via: [:get, :post]
      match "staff/#{action}/:id", to: 'staff#'+action, via: [:get, :post]
    end
  end

  # ##### Public Zone
  # %w{about join_us privacy registration_confirmation}.each do |page|
  #   match page, to: 'public#'+page, as: page, via: :get
  # end

  # %w{events set_password login contact contact_submit register forgot_password style_guide}.each do |page|
  #   match page, to: 'public#'+page, as: page, via: [:get, :post]
  # end

  # ##### Staff Zone
  # match 'staff', to: 'staff#index', via: :get
  # %w(
  #   cancel_interview
  #   check_if_logged_in
  #   contact
  #   deactivate_account
  #   deselect_event
  #   events
  #   get_hired_status
  #   get_non_eu_id_view
  #   get_training_module
  #   index
  #   library_item
  #   logout
  #   mark_training_module_complete
  #   reactivate_account
  #   refresh_contracts
  #   refresh_events
  #   refresh_online_interview_tab
  #   relogin
  #   select_event
  #   set_password
  #   sign_up_for_interview
  #   terms
  #   update_bank_details
  #   update_contact_preferences
  #   update_nationality
  #   update_personal_details
  #   update_questions
  #   update_tax_choice
  #   update_training_module_progress
  #   update_uk_id_type
  #   upload_birth_certificate
  #   upload_eu_passport
  #   upload_passport_and_visa
  #   upload_photo
  #   upload_uk_birth_certificate
  #   upload_uk_passport
  #   upload_uk_passport_images
  #   unsubscribe
  # ).each do |action|
  #   match "staff/#{action}",     to: 'staff#'+action, via: [:get, :post]
  #   match "staff/#{action}/:id", to: 'staff#'+action, via: [:get, :post]
  # end

  # ##### Client Zone
  # %w[login activate set_password].each do |page|
  #   match "client/#{page}", to: 'client#'+page, via: [:get, :post]
  # end

  ##### Office Zone
  match 'office', to: 'office#index', via: [:get, :post]
  %w(
    accept_change_request
    add_remove_gigs
    add_remove_pay_weeks
    approve_ids
    assignment_details
    main_work_area_events
    blacklist_employee
    check_if_pay_weeks_okay_to_export
    clear_confirmed_on_gigs
    clear_misc_flag
    create_assignment_email_template
    create_bulk_interview
    create_client
    create_content
    create_event
    create_event_task
    create_faq_entry
    create_gig
    create_gigs
    create_invoice
    create_library_item
    create_officer
    create_pay_weeks_for_event
    create_pay_weeks_from_pay_weeks
    create_prospect
    create_test_event
    create_timesheet_entries_for_event
    data
    delete_assignment
    delete_assignment_email_template
    delete_bulk_interview
    delete_client
    delete_client_contact
    delete_content
    delete_event
    delete_event_task
    delete_expense
    delete_faq_entry
    delete_gig
    bulk_info_of_applicants
    delete_gig_requests
    delete_gigs
    delete_interview_block
    delete_invoice
    delete_job
    delete_library_item
    delete_location
    delete_officer
    delete_shift
    delete_pay_weeks
    delete_tag
    delete_team_leader_role
    delete_timesheet_entries
    download_accreditation
    download_custom_gig_report
    download_custom_registration_sheet
    download_custom_registration_sheet_daily
    download_etihad_package
    download_webapp_data
    download_scanned_ids_data
    download_scanned_bar_ids_data
    download_dbs_data
    download_library_file
    download_report
    duplicate_assignments_daily
    duplicate_assignment_email_template
    duplicate_assignments_weekly
    duplicate_event
    export_pay_week
    fetch_assignment_email_preview
    fetch_change_request_log
    fetch_profile
    fetch_timesheet_notes
    fetch_session_log
    generate_forgot_password_text
    get_event_manager
    get_no_of_interviews
    index
    invite_client_contact
    lock_officer
    login
    logout
    payroll_detail_changes
    prospect_scanned_bar_licenses
    prospect_scanned_dbses
    prospect_scanned_ids
    reject_change_request
    reject_ids
    reject_photo
    relogin
    remove_unconfirmed_gigs
    rotate_scanned_bar_license
    rotate_scanned_dbs
    rotate_scanned_id
    scanned_bar_license_image
    scanned_dbs_image
    scanned_id_image
    share_code_file
    send_assignment_emails
    set_spare
    status_validate
    tasks_window
    unlock_account
    unlock_officer
    update_assignments
    update_assignment_email_templates
    update_bulk_interview
    update_client
    update_client_contacts
    update_content
    update_expenses
    update_event
    update_events
    update_event_task
    update_event_tasks
    update_event_tasks_from_event
    remove_event_tasks
    update_faq_entry
    update_gig_requests
    update_gigs
    update_interview_blocks
    update_invoice
    update_invoices
    update_jobs
    update_feature_jobs
    update_public_jobs
    update_library_item
    update_locations
    update_officer
    update_prospect
    update_prospects
    send_confirmation_email
    update_shifts
    hire
    update_pay_weeks
    update_tags
    update_team_leader_roles
    update_timesheet_entries
    upload_bulk_interview_photo
    upload_content_thumbnail
    upload_event_photo
    upload_prospect_photo
    upload_scanned_bar_license
    upload_scanned_dbses
    upload_scanned_ids
    upload_scanned_timesheets
    upload_share_code
    get_jobs
    save_job
    put_opening_word_to_job
    duplicate_job_info
  ).each do |action|
    match "office/#{action}",     to: 'office#'+action, via: [:get, :post]
    match "office/#{action}/:id", to: 'office#'+action, via: [:get, :post, :patch]
  end
end
