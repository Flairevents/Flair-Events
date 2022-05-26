# This is used when retrieving data for the Office Zone

require 'models/base'

module Models
  Account = Base.new('accounts', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:user_id,                 'number'),
    ListColumn.new(:locked,                  'boolean')],
      where: ["accounts.user_type = 'Officer'"])

  Assignment = Base.new('assignments', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:job_id,                  'number'),
    ListColumn.new(:shift_id,                'number'),
    ListColumn.new(:location_id,             'number'),
    ListColumn.new(:staff_needed,            'number'),
    ListColumn.new(:created_at,              'datetime',    null: true)])

  AssignmentEmailTemplate = Base.new('assignment_email_templates', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:office_message,          'string'),
    ListColumn.new(:arrival_time,            'string'),
    ListColumn.new(:meeting_location,        'string'),
    ListColumn.new(:meeting_location_coords, 'string'),
    ListColumn.new(:on_site_contact,         'string'),
    ListColumn.new(:contact_number,          'string'),
    ListColumn.new(:confirmation,            'string', null: true),
    ListColumn.new(:uniform,                 'string'),
    ListColumn.new(:welfare,                 'string'),
    ListColumn.new(:transport,               'string'),
    ListColumn.new(:details,                 'string'),
    ListColumn.new(:additional_info,         'string')])

  Booking = Base.new('bookings', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_client_id,         'number'),
    ListColumn.new(:client_contact_id,       'number', null: true),
    ListColumn.new(:dates,                   'string', null: true),
    ListColumn.new(:timings,                 'string', null: true),
    ListColumn.new(:crew_required,           'string', null: true),
    ListColumn.new(:job_description,         'string', null: true),
    ListColumn.new(:event_description,       'string', null: true),
    ListColumn.new(:selling_points,          'string', null: true),
    ListColumn.new(:staff_qualities,         'string', null: true),
    ListColumn.new(:uniform,                 'string', null: true),
    ListColumn.new(:food,                    'string', null: true),
    ListColumn.new(:breaks,                  'string', null: true),
    ListColumn.new(:wages,                   'string', null: true),
    ListColumn.new(:terms,                   'string', null: true),
    ListColumn.new(:invoicing,               'string', null: true),
    ListColumn.new(:timesheets,              'string', null: true),
    ListColumn.new(:minimum_hours,           'string', null: true),
    ListColumn.new(:any_other_information,   'string', null: true),
    ListColumn.new(:office_notes,            'string', null: true),
    ListColumn.new(:amendments,              'string', null: true),
    ListColumn.new(:transport,               'string', null: true),
    ListColumn.new(:meeting_location,        'string', null: true),
    ListColumn.new(:date_sent,               'date',   null: true),
    ListColumn.new(:date_received,           'date',   null: true),
    ListColumn.new(:health_safety,           'string', null: true),
    ListColumn.new(:rates,                   'string', null: true, confidential: true)])

  BulkInterview = Base.new('bulk_interviews', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:venue,                   'string'),
    ListColumn.new(:positions,               'string', null: true),
    ListColumn.new(:date_start,              'date'),
    ListColumn.new(:date_end,                'date'),
    ListColumn.new(:address,                 'string', null: true),
    ListColumn.new(:city,                    'string', null: true),
    ListColumn.new(:post_code,               'string', null: true),
    ListColumn.new(:note_for_applicant,      'string', null: true),
    ListColumn.new(:target_region_id,        'number', null: true),
    ListColumn.new(:region_id,               'number', null: true),
    ListColumn.new(:photo,                   'string', null: true),
    ListColumn.new(:directions,              'string', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:interview_type,          'string')])

  BulkInterviewEvent = Base.new('bulk_interview_events', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:bulk_interview_id,       'number'),
    ListColumn.new(:event_id,                'number')])

  EventSize = Base.new('event_sizes', [
      ListColumn.new(:id,                  'number'),
      ListColumn.new(:name,                'string')])

  Client = Base.new('clients', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:active,                  'boolean'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:company_type,            'string', null: true),
    ListColumn.new(:address,                 'string', null: true),
    ListColumn.new(:phone_no,                'string', null: true),
    ListColumn.new(:email,                   'string', null: true),
    ListColumn.new(:accountant_email,        'string', null: true),
    ListColumn.new(:flair_contact,           'string', null: true),
    ListColumn.new(:primary_client_contact_id,'number', null: true),
    ListColumn.new(:terms_date_sent,         'date',   null: true),
    ListColumn.new(:terms_date_received,     'date',   null: true),
    ListColumn.new(:terms_client_contact_id, 'number', null: true),
    ListColumn.new(:safety_date_sent,        'date',   null: true),
    ListColumn.new(:safety_date_received,    'date',   null: true),
    ListColumn.new(:safety_client_contact_id,'number', null: true),
    ListColumn.new(:notes,                   'string', null: true),
    ListColumn.new(:invoice_notes,           'string', null: true)])

  ClientContact = Base.new('client_contacts', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:active,                  'boolean'),
    ListColumn.new(:first_name,              'string'),
    ListColumn.new(:last_name,               'string'),
    ListColumn.new(:mobile_no,               'string', null: true),
    ListColumn.new(:email,                   'string'),
    ListColumn.new(:client_id,               'number'),
    ListColumn.new(:account_status,          'string')])

  Event = Base.new('events', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:display_name,            'string', null: true),
    ListColumn.new(:category_id,             'number', null: true),
    ListColumn.new(:date_start,              'date'),
    ListColumn.new(:date_end,                'date'),
    ListColumn.new(:public_date_start,       'date'),
    ListColumn.new(:public_date_end,         'date'),
    ListColumn.new(:date_callback_due,       'date', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:fullness,                'string'),
    ListColumn.new(:blurb_legacy,            'string', null: true),
    ListColumn.new(:blurb_title,             'string'),
    ListColumn.new(:blurb_subtitle,          'string'),
    ListColumn.new(:blurb_opening,           'string'),
    ListColumn.new(:blurb_closing,           'string'),
    ListColumn.new(:blurb_job,               'string'),
    ListColumn.new(:blurb_shift,             'string'),
    ListColumn.new(:blurb_wage_additional,   'string'),
    ListColumn.new(:blurb_uniform,           'string'),
    ListColumn.new(:blurb_transport,         'string'),
    ListColumn.new(:leader_general,          'string'),
    ListColumn.new(:leader_meeting_location, 'string'),
    ListColumn.new(:leader_meeting_location_coords, 'string', null: true),
    ListColumn.new(:leader_accomodation,     'string'),
    ListColumn.new(:leader_job_role,         'string'),
    ListColumn.new(:leader_arrival_time,     'string'),
    ListColumn.new(:leader_flair_phone_no,  'string'),
    ListColumn.new(:leader_handbooks,        'string'),
    ListColumn.new(:leader_staff_job_roles,  'string'),
    ListColumn.new(:leader_staff_arrival,    'string'),
    ListColumn.new(:leader_energy,           'string'),
    ListColumn.new(:leader_uniform,          'string'),
    ListColumn.new(:leader_food,             'string'),
    ListColumn.new(:leader_transport,        'string'),
    ListColumn.new(:leader_client_contact_id,'string', null: true),
    ListColumn.new(:location,                'string', null: true),
    ListColumn.new(:address,                 'string', null: true),
    ListColumn.new(:post_code,               'string', null: true),
    ListColumn.new(:region_id,               'string', null: true),
    ListColumn.new(:website,                 'string', null: true),
    ListColumn.new(:notes,                   'string'),
    ListColumn.new(:site_manager,            'string', null: true),
    ListColumn.new(:office_manager_id,       'number', null: true),
    ListColumn.new(:photo,                   'string', null: true),
    ListColumn.new(:show_in_history,         'boolean'),
    ListColumn.new(:show_in_public,          'boolean', null: true),
    ListColumn.new(:show_in_home,            'boolean'),
    ListColumn.new(:show_in_payroll,         'boolean'),
    ListColumn.new(:show_in_time_clocking_app,'boolean'),
    ListColumn.new(:remove_task,             'boolean'),
    ListColumn.new(:staff_needed,            'number', null: true),
    ListColumn.new(:additional_staff,        'number'),
    ListColumn.new(:gigs_count,              'number'),
    ListColumn.new(:is_concert,              'boolean'),
    ListColumn.new(:jobs_description,        'string', null: true),
    ListColumn.new(:accom_status,            'string'),
    ListColumn.new(:accom_hotel_name,        'string', null: true),
    ListColumn.new(:accom_address,           'string', null: true),
    ListColumn.new(:accom_phone,             'string', null: true),
    ListColumn.new(:accom_parking,           'string', null: true),
    ListColumn.new(:accom_total_cost,        'string', null: true),
    ListColumn.new(:accom_booking_ref,       'string', null: true),
    ListColumn.new(:accom_notes,             'string', null: true),
    ListColumn.new(:accom_room_info,         'string', null: true),
    ListColumn.new(:accom_distance,          'string', null: true),
    ListColumn.new(:accom_booking_dates,     'string', null: true),
    ListColumn.new(:accom_parking,           'string', null: true),
    ListColumn.new(:accom_wifi,              'string', null: true),
    ListColumn.new(:accom_cancellation_policy,'string', null: true),
    ListColumn.new(:accom_payment_method,    'string', null: true),
    ListColumn.new(:accom_booked_by,         'string', null: true),
    ListColumn.new(:accom_booking_dates,     'string', null: true),
    ListColumn.new(:expense_notes,           'string', null: true),
    ListColumn.new(:post_notes,              'string', null: true),
    ListColumn.new(:default_job_id,          'number', null: true),
    ListColumn.new(:default_location_id,     'number', null: true),
    ListColumn.new(:default_assignment_id,   'number', null: true),
    ListColumn.new(:require_training_ethics, 'boolean'),
    ListColumn.new(:require_training_customer_service,  'boolean'),
    ListColumn.new(:require_training_health_safety,     'boolean'),
    ListColumn.new(:require_training_sports,            'boolean'),
    ListColumn.new(:require_training_bar_hospitality,   'boolean'),
    ListColumn.new(:admin_completed,                    'boolean'),
    ListColumn.new(:paid_breaks,                        'boolean'),
    ListColumn.new(:show_in_ongoing,                    'boolean'),
    ListColumn.new(:show_in_featured,                   'boolean'),
    ListColumn.new(:show_in_planner,                    'boolean'),
    ListColumn.new(:requires_booking,                   'boolean'),
    ListColumn.new(:send_scheduled_to_work_auto_email,  'boolean'),
    ListColumn.new(:size_id,                            'number', null: true),
    ListColumn.new(:reviewed_by_manager,                'number', null: true),
    ListColumn.new(:accom_booking_via,                  'string', null: true),
    ListColumn.new(:accom_refund_date,                  'date', null: true),
    ListColumn.new(:is_restricted,                      'boolean', null: true),
    ListColumn.new(:has_bar,                            'boolean'),
    ListColumn.new(:has_sport,                          'boolean'),
    ListColumn.new(:has_hospitality,                    'boolean'),
    ListColumn.new(:has_festivals,                      'boolean'),
    ListColumn.new(:has_office,                         'boolean'),
    ListColumn.new(:has_retail,                         'boolean'),
    ListColumn.new(:has_warehouse,                      'boolean'),
    ListColumn.new(:has_promotional,                    'boolean'),
    ListColumn.new(:shift_start_time,                   'string'),
    ListColumn.new(:featured_job,                       'number'),
    ListColumn.new(:request_message,                       'string'),
    ListColumn.new(:spares_message,                       'string'),
    ListColumn.new(:applicants_message,                       'string'),
    ListColumn.new(:action_message,                       'string'),
    ListColumn.new(:other_info,                       'string'),
    ListColumn.new(:created_at,                         'datetime',    null: true),
    ListColumn.new(:senior_manager_id,                       'number'),
  ])

  EventClient = Base.new('event_clients', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:client_id,               'number')])

  EventDate = Base.new('event_dates', [
    ListColumn.new(:id,          'number'),
    ListColumn.new(:event_id,    'number'),
    ListColumn.new(:date,        'date'),
    ListColumn.new(:tax_week_id, 'number')])

  EventTask = Base.new('event_tasks', [
    ListColumn.new(:id,         'number'),
    ListColumn.new(:event_id,   'number'),
    ListColumn.new(:officer_id, 'number'),
    ListColumn.new(:second_officer_id, 'number'),
    ListColumn.new(:template_id, 'number'),
    ListColumn.new(:task,       'string'),
    ListColumn.new(:notes,      'string'),
    ListColumn.new(:due_date,   'date'),
    ListColumn.new(:completed,  'boolean'),
    ListColumn.new(:completed_date, 'date', null: true),
    ListColumn.new(:additional_notes,  'string'),
    ListColumn.new(:manager_notes,  'string'),
    ListColumn.new(:confirmed,  'boolean'),
    ListColumn.new(:tax_week_id, 'number'),
    ListColumn.new(:task_completed,  'boolean')])

  EventTaskTemplate = Base.new('event_task_templates', [
    ListColumn.new(:id,    'number'),
    ListColumn.new(:task,  'string'),
    ListColumn.new(:notes, 'string')])

  Expense = Base.new('expenses', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:cost,                    'number', null: true),
    ListColumn.new(:notes,                   'string', null: true)])

  FaqEntry = Base.new('faq_entries', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:question,                'string'),
    ListColumn.new(:answer,                  'string'),
    ListColumn.new(:position,                'number'),
    ListColumn.new(:topic,                   'string')])

  Questionnaire = Base.new('questionnaires', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:prospect_id,             'number',),
    ListColumn.new(:enjoy_working_on_team,   'boolean',),
    ListColumn.new(:interested_in_bar,       'boolean',),
    ListColumn.new(:promotions_experience,   'boolean',),
    ListColumn.new(:retail_experience,       'boolean',),
    ListColumn.new(:interested_in_marshal,   'boolean',),
    ListColumn.new(:staff_leadership_experience,          'boolean'),
    ListColumn.new(:bar_management_experience,            'boolean'),
    ListColumn.new(:evening_shifts_work,                  'boolean'),
    ListColumn.new(:day_shifts_work,                      'boolean'),
    ListColumn.new(:weekends_work,                        'boolean'),
    ListColumn.new(:week_days_work,                       'boolean'),
    ListColumn.new(:contact_via_whatsapp,                 'boolean'),
    ListColumn.new(:contact_via_text,                     'boolean'),
    ListColumn.new(:contact_via_email,                    'boolean'),
    ListColumn.new(:contact_via_telephone,                'boolean'),
    ListColumn.new(:scottish_personal_licence_qualification,          'boolean'),
    ListColumn.new(:dbs_qualification,                                'boolean'),
    ListColumn.new(:food_health_level_two_qualification,              'boolean'),
    ListColumn.new(:english_personal_licence_qualification,           'boolean'),
    ListColumn.new(:has_bar_and_hospitality,              'boolean'),
    ListColumn.new(:has_sport_and_outdoor,                'boolean'),
    ListColumn.new(:has_promotional_and_street_marketing, 'boolean'),
    ListColumn.new(:has_merchandise_and_retail,           'boolean'),
    ListColumn.new(:has_reception_and_office_admin,       'boolean'),
    ListColumn.new(:has_festivals_and_concerts,           'boolean'),
    ListColumn.new(:team_leader_experience,  'boolean',)])

  Gig = Base.new('gigs', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:prospect_id,             'number'),
    ListColumn.new(:job_id,                  'number', null: true),
    ListColumn.new(:location_id,             'number', null: true),
    ListColumn.new(:notes,                   'string', null: true),
    ListColumn.new(:rating,                  'number', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:miscellaneous_boolean,   'boolean'),
    ListColumn.new(:published,               'boolean')])

  GigAssignment = Base.new('gig_assignments', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gig_id,                  'number'),
    ListColumn.new(:assignment_id,           'number')])

  GigRequest = Base.new('gig_requests', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:gig_id,                  'number'),
    ListColumn.new(:prospect_id,             'number'),
    ListColumn.new(:created_at,              'number', null: true),
    ListColumn.new(:spare,                   'boolean'),
    ListColumn.new(:is_best,                 'boolean'),
    ListColumn.new(:left_voice_message,      'boolean'),
    ListColumn.new(:email_status,            'boolean'),
    ListColumn.new(:texted,                  'boolean'),
    ListColumn.new(:job_id,                  'number'),
    ListColumn.new(:notes,                   'string', null: true)])

  GigTag = Base.new('gig_tags', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gig_id,                  'number'),
    ListColumn.new(:tag_id,                  'number')])

  GigTaxWeek = Base.new('gig_tax_weeks', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gig_id,                  'number'),
    ListColumn.new(:tax_week_id,             'number'),
    ListColumn.new(:assignment_email_type,   'string', null: true),
    ListColumn.new(:assignment_email_template_id,'string', null: true),
    ListColumn.new(:confirmed,               'boolean')])

  QuoteRequest = Base.new('quote_requests',  [
    ListColumn.new(:id,               'number'),
    ListColumn.new(:name,             'string'),
    ListColumn.new(:company_name,     'string'),
    ListColumn.new(:telephone,        'string'),
    ListColumn.new(:email,            'string'),
    ListColumn.new(:contract_name,    'string'),
    ListColumn.new(:location,         'string'),
    ListColumn.new(:post_code,        'string'),
    ListColumn.new(:start_date,       'datetime'),
    ListColumn.new(:finish_date,      'datetime'),
    ListColumn.new(:job_position,     'string'),
    ListColumn.new(:full_range,       'string'),
    ListColumn.new(:number_of_people, 'string'),
    ListColumn.new(:wage_rates,       'string'),
    ListColumn.new(:other_facts,      'string')])

  Interview = Base.new('interviews', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:interview_slot_id,       'number'),
    ListColumn.new(:interview_block_id,      'number'),
    ListColumn.new(:time_type,               'string'),
    ListColumn.new(:telephone_call_interview,'boolean'),
    ListColumn.new(:video_call_interview,    'boolean'),
    ListColumn.new(:prospect_id,             'number')])

  InterviewBlock = Base.new('interview_blocks', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:bulk_interview_id,       'number'),
    ListColumn.new(:date,                    'date'),
    ListColumn.new(:time_start,              'time'),
    ListColumn.new(:time_end,                'time'),
    ListColumn.new(:slot_mins,               'number'),
    ListColumn.new(:number_of_applicants_per_slot,'number'),
    ListColumn.new(:is_morning,              'boolean'),
    ListColumn.new(:morning_applicants,      'number'),
    ListColumn.new(:is_afternoon,             'boolean'),
    ListColumn.new(:afternoon_applicants,     'number'),
    ListColumn.new(:is_evening,               'boolean'),
    ListColumn.new(:evening_applicants,        'number'),
    ListColumn.new(:morning_interviews,        'number'),
    ListColumn.new(:afternoon_interviews,        'number'),
    ListColumn.new(:evening_interviews,        'number')])

  InterviewSlot = Base.new('interview_slots', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:interview_block_id,      'number'),
    ListColumn.new(:time_start,              'time'),
    ListColumn.new(:time_end,                'time'),
    ListColumn.new(:interviews_count,        'number')])

  Invoice = Base.new('invoices', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_client_id,         'number'),
    ListColumn.new(:who,                     'string', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:date_emailed,            'date',   null: true),
    ListColumn.new(:tax_week_id,             'number')])

  Job = Base.new('jobs', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:public_name,             'string', null: true),
    ListColumn.new(:description,             'string', null: true),
    ListColumn.new(:pay_17_and_under,        'number'),
    ListColumn.new(:pay_21_and_over,         'number'),
    ListColumn.new(:pay_18_and_over,         'number'),
    ListColumn.new(:pay_25_and_over,         'number'),
    ListColumn.new(:number_of_positions,     'number'),
    ListColumn.new(:shift_information,       'string'),
    ListColumn.new(:uniform_information,     'string'),
    ListColumn.new(:other_information,       'string'),
    ListColumn.new(:new_description,         'string'),
    ListColumn.new(:include_in_description,  'boolean')])

  Location = Base.new('locations', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:type,                    'string')])

  LibraryItem = Base.new('library_items', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:filename,                'string')])

  LogEntry = Base.new('admin_log_entries', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:type,                    'string'),
    ListColumn.new(:data,                    'object')])

  Officer = Base.new('officers', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:first_name,              'string'),
    ListColumn.new(:last_name,               'string'),
    ListColumn.new(:email,                   'string'),
    ListColumn.new(:role,                    'string'),
    ListColumn.new(:active_operational_manager, 'boolean'),
    ListColumn.new(:senior_manager, 'boolean')
  ])

  PayWeek = Base.new('pay_weeks', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:job_id,                  'number', null: true),
    ListColumn.new(:event_id,                'number', null: true),
    ListColumn.new(:prospect_id,             'number'),
    ListColumn.new(:tax_week_id,             'number'),
    ListColumn.new(:monday,                  'number'),
    ListColumn.new(:tuesday,                 'number'),
    ListColumn.new(:wednesday,               'number'),
    ListColumn.new(:thursday,                'number'),
    ListColumn.new(:friday,                  'number'),
    ListColumn.new(:saturday,                'number'),
    ListColumn.new(:sunday,                  'number'),
    ListColumn.new(:rate,                    'number', null: true),
    ListColumn.new(:deduction,               'number'),
    ListColumn.new(:allowance,               'number'),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:type,                    'string')])

  PostArea = Base.new('post_areas', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:region_id,               'number'),
    ListColumn.new(:subcode,                 'string'),
    ListColumn.new(:latitude,                'number'),
    ListColumn.new(:longitude,               'number')],
      has_timestamps: false)

  Prospect = Base.new('prospects', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gender,                  'string', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:client_id,               'number', null: true),
    ListColumn.new(:email,                   'string'),
    ListColumn.new(:first_name,              'string'),
    ListColumn.new(:last_name,               'string'),
    ListColumn.new(:date_of_birth,           'date',   null: true),
    ListColumn.new(:nationality_id,          'number', null: true),
    ListColumn.new(:country,                 'string', null: true),
    ListColumn.new(:address,                 'string', null: true),
    ListColumn.new(:address2,                'string', null: true),
    ListColumn.new(:city,                    'string', null: true),
    ListColumn.new(:post_code,               'string', null: true),
    ListColumn.new(:region_id,               'number', null: true),
    ListColumn.new(:mobile_no,               'string', null: true),
    ListColumn.new(:home_no,                 'string', null: true),
    ListColumn.new(:emergency_no,            'string', null: true),
    ListColumn.new(:emergency_name,          'string', null: true),
    ListColumn.new(:tax_choice,              'string', null: true),
    ListColumn.new(:ni_number,               'string', null: true),
    ListColumn.new(:bank_account_name,       'string', null: true),
    ListColumn.new(:bank_sort_code,          'string', null: true),
    ListColumn.new(:bank_account_no,         'string', null: true),
    ListColumn.new(:bar_experience,          'string', null: true),
    ListColumn.new(:bar_license_type,        'string', null: true),
    ListColumn.new(:bar_license_no,          'string', null: true),
    ListColumn.new(:bar_license_issued_by,   'string', null: true),
    ListColumn.new(:bar_license_expiry,      'date',   null: true),
    ListColumn.new(:training_type,           'string', null: true),
    ListColumn.new(:agreed_terms,            'boolean', select: 'prospects.datetime_agreement IS NOT NULL', fn: '!!object.datetime_agreement'),
    ListColumn.new(:id_number,               'string', null: true),
    ListColumn.new(:visa_number,             'string', null: true),
    ListColumn.new(:id_type,                 'string', null: true),
    ListColumn.new(:id_expiry,               'date',   null: true),
    ListColumn.new(:visa_issue_date,         'date',   null: true),
    ListColumn.new(:visa_expiry,             'date',   null: true),
    ListColumn.new(:visa_indefinite,         'boolean'),
    ListColumn.new(:id_sighted,              'date',   null: true),
    ListColumn.new(:notes,                   'string', null: true),
    ListColumn.new(:registered,              'date',   select: 'DATE(prospects.created_at)', fn: 'object.created_at'),
    ListColumn.new(:good_sport,              'boolean'),
    ListColumn.new(:good_bar,                'boolean'),
    ListColumn.new(:good_promo,              'boolean'),
    ListColumn.new(:good_hospitality,        'boolean'),
    ListColumn.new(:good_management,         'boolean'),
    ListColumn.new(:date_start,              'date',   null: true),
    ListColumn.new(:date_end,                'date',   null: true),
    ListColumn.new(:student_loan,            'boolean'),
    ListColumn.new(:applicant_status,        'string', null: true),
    ListColumn.new(:rating,                  'number', null: true),
    ListColumn.new(:photo,                   'string', null: true),
    ListColumn.new(:has_large_photo,         'boolean'),
    ListColumn.new(:prefers_in_person,       'boolean'),
    ListColumn.new(:prefers_phone,           'boolean'),
    ListColumn.new(:prefers_skype,           'boolean'),
    ListColumn.new(:prefers_facetime,        'boolean'),
    ListColumn.new(:preferred_phone,         'string', null: true),
    ListColumn.new(:preferred_skype,         'string', null: true),
    ListColumn.new(:preferred_facetime,      'string', null: true),
    ListColumn.new(:prefers_morning,         'boolean'),
    ListColumn.new(:prefers_afternoon,       'boolean'),
    ListColumn.new(:prefers_early_evening,   'boolean'),
    ListColumn.new(:prefers_midweek,         'boolean'),
    ListColumn.new(:prefers_weekend,         'boolean'),
    ListColumn.new(:performance_notes,       'string', null: true),
    ListColumn.new(:manager_level,           'string', null: true),
    ListColumn.new(:last_login,              'date', null: true),
    ListColumn.new(:training_ethics,         'boolean'),
    ListColumn.new(:training_customer_service,'boolean'),
    ListColumn.new(:training_health_safety,  'boolean'),
    ListColumn.new(:training_sports,         'boolean'),
    ListColumn.new(:training_bar_hospitality,'boolean'),
    ListColumn.new(:send_marketing_email,    'boolean'),
    ListColumn.new(:qualification_food_health_2,'boolean'),
    ListColumn.new(:qualification_dbs,       'boolean'),
    ListColumn.new(:headquarter,       'string'),
    ListColumn.new(:texted_date,       'date',   null: true),
    ListColumn.new(:email_status,       'string'),
    ListColumn.new(:missed_interview_date,       'date',   null: true),
    ListColumn.new(:left_voice_message,       'boolean'),
    ListColumn.new(:flair_image,        'number'),
    ListColumn.new(:experienced,        'number'),
    ListColumn.new(:chatty,             'number'),
    ListColumn.new(:confident,          'number'),
    ListColumn.new(:language,           'number'),
    ListColumn.new(:big_teams,          'string'),
    ListColumn.new(:all_teams,          'string'),
    ListColumn.new(:prospect_character, 'string'),
    ListColumn.new(:team_notes,         'string', null: true),
    ListColumn.new(:bespoke,            'string'),
    ListColumn.new(:flag_photo,                       'string'),
    ListColumn.new(:cancelled_contracts,              'string'),
    ListColumn.new(:cancelled_eighteen_hrs_contracts, 'string'),
    ListColumn.new(:no_show_contracts,                'string'),
    ListColumn.new(:non_confirmed_contracts,          'string'),
    ListColumn.new(:held_spare_contracts,             'string'),
    ListColumn.new(:completed_contracts,              'string'),
    ListColumn.new(:dbs_certificate_number,           'string'),
    ListColumn.new(:dbs_issue_date,                   'date',   null: true),
    ListColumn.new(:has_bar_and_hospitality,              'boolean'),
    ListColumn.new(:has_sport_and_outdoor,                'boolean'),
    ListColumn.new(:has_promotional_and_street_marketing, 'boolean'),
    ListColumn.new(:has_merchandise_and_retail,           'boolean'),
    ListColumn.new(:has_reception_and_office_admin,       'boolean'),
    ListColumn.new(:has_festivals_and_concerts,           'boolean'),
    ListColumn.new(:has_bar_management_experience,        'boolean'),
    ListColumn.new(:has_staff_leadership_experience,      'boolean'),
    ListColumn.new(:has_hospitality_marketing,            'boolean'),
    ListColumn.new(:has_warehouse_marketing,              'boolean'),
    ListColumn.new(:warehouse_skill,                      'boolean'),
    ListColumn.new(:hospitality_skill,                    'boolean'),
    ListColumn.new(:bar_skill,                            'boolean'),
    ListColumn.new(:sport_skill,                          'boolean'),
    ListColumn.new(:festival_skill,                       'boolean'),
    ListColumn.new(:office_skill,                         'boolean'),
    ListColumn.new(:promo_skill,                          'boolean'),
    ListColumn.new(:retail_skill,                         'boolean'),
    ListColumn.new(:bar_manager_skill,                    'boolean'),
    ListColumn.new(:staff_leader_skill,                   'boolean'),
    ListColumn.new(:city_of_study,                   'string'),
    ListColumn.new(:has_c19_test,                   'boolean'),
    ListColumn.new(:is_clean,                   'boolean'),
    ListColumn.new(:is_convicted,                   'boolean'),
    ListColumn.new(:c19_tt_at,                   'date',   null: true),
    ListColumn.new(:test_site_code,                   'string',   null: true),
    ListColumn.new(:created_at,                       'datetime',    null: true),
    ListColumn.new(:share_code,                       'string',    null: true),
    ListColumn.new(:dbs_qualification_type,                   'boolean', null: true),
    ListColumn.new(:condition,                   'string', null: true)])

  ActionTaken = Base.new('action_takens', [
    ListColumn.new(:id,                    'number'),
    ListColumn.new(:event_id,              'number'),
    ListColumn.new(:prospect_id,           'number'),
    ListColumn.new(:action,                'string'),
    ListColumn.new(:created_at,            'datetime',    null: true),
    ListColumn.new(:reason,                'string')])

  Region = Base.new('regions', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string')])

  Shift = Base.new('shifts', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:tax_week_id,             'number', null: true),
    ListColumn.new(:date,                    'date'),
    ListColumn.new(:time_start,              'time'),
    ListColumn.new(:time_end,                'time')])

  Tag = Base.new('tags', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:name,                    'string'),
    ListColumn.new(:event_id,                'number')])

  TaxWeek = Base.new('tax_weeks', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:date_start,              'date'),
    ListColumn.new(:date_end,                'date'),
    ListColumn.new(:tax_year_id,             'number'),
    ListColumn.new(:week,                    'number')])

  TaxYear = Base.new('tax_years', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:date_start,              'date'),
    ListColumn.new(:date_end,                'date')])

  TeamLeaderRole = Base.new('team_leader_roles', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:user_id,                 'number'),
    ListColumn.new(:user_type,               'string'),
    ListColumn.new(:enabled,                 'boolean') ])

  TextBlock = Base.new('text_blocks', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:key,                     'string'),
    ListColumn.new(:type,                    'string'),
    ListColumn.new(:title,                   'string', null: true),
    ListColumn.new(:status,                  'string', null: true),
    ListColumn.new(:thumbnail,               'string', null: true),
    ListColumn.new(:updated_at,              'datetime'),
    ListColumn.new(:contents,                'string')])

  TimeClockReport = Base.new('time_clock_reports', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:event_id,                'number'),
    ListColumn.new(:date,                    'date'),
    ListColumn.new(:user_id,                 'number'),
    ListColumn.new(:user_type,               'string'),
    ListColumn.new(:tax_week_id,             'number'),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:notes,                   'string'),
    ListColumn.new(:client_notes,            'string'),
    ListColumn.new(:client_rating,           'string'),
    ListColumn.new(:signed_by_name,          'string'),
    ListColumn.new(:signed_by_job_title,     'string'),
    ListColumn.new(:signed_by_company_name,  'string'),
    ListColumn.new(:signature,               'string', null: true),
    ListColumn.new(:date_submitted,          'datetime')])

  TimesheetEntry = Base.new('timesheet_entries', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gig_assignment_id,       'number'),
    ListColumn.new(:tax_week_id,             'number'),
    ListColumn.new(:time_start,              'time',   null: true),
    ListColumn.new(:time_end,                'time',   null: true),
    ListColumn.new(:break_minutes,           'number', null: true),
    ListColumn.new(:status,                  'string'),
    ListColumn.new(:rating,                  'number', null: true),
    ListColumn.new(:notes,                   'string', null: true),
    ListColumn.new(:invoiced,                'boolean'),
    ListColumn.new(:time_clock_report_id,    'number', null: true)])

  UnworkedGigAssignment = Base.new('unworked_gig_assignments', [
    ListColumn.new(:id,                      'number'),
    ListColumn.new(:gig_id,                  'number'),
    ListColumn.new(:assignment_id,           'number'),
    ListColumn.new(:reason,                  'string')])
end
