# Machine generated, do not edit
# See lib/tasks/serialization.rake
require 'models'
require 'oj'
module Models::Export
def export_account_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Account.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_account_object(object)
  [
    object.id,
    object.user_id,
    object.locked
  ]
end

def export_actiontaken_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::ActionTaken.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_actiontaken_object(object)
  [
    object.id,
    object.event_id,
    object.prospect_id,
    object.action,
    object.created_at,
    object.reason
  ]
end

def export_assignment_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Assignment.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_assignment_object(object)
  [
    object.id,
    object.event_id,
    object.job_id,
    object.shift_id,
    object.location_id,
    object.staff_needed,
    object.created_at
  ]
end

def export_assignmentemailtemplate_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::AssignmentEmailTemplate.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_assignmentemailtemplate_object(object)
  [
    object.id,
    object.event_id,
    object.name,
    object.office_message,
    object.arrival_time,
    object.meeting_location,
    object.meeting_location_coords,
    object.on_site_contact,
    object.contact_number,
    object.confirmation,
    object.uniform,
    object.welfare,
    object.transport,
    object.details,
    object.additional_info
  ]
end

def export_booking_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Booking.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_booking_object(object)
  [
    object.id,
    object.event_client_id,
    object.client_contact_id,
    object.dates,
    object.timings,
    object.crew_required,
    object.job_description,
    object.event_description,
    object.selling_points,
    object.staff_qualities,
    object.uniform,
    object.food,
    object.breaks,
    object.wages,
    object.terms,
    object.invoicing,
    object.timesheets,
    object.minimum_hours,
    object.any_other_information,
    object.office_notes,
    object.amendments,
    object.transport,
    object.meeting_location,
    (val = object.date_sent; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_received; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.health_safety,
    object.rates
  ]
end

def export_bulkinterview_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::BulkInterview.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_bulkinterview_object(object)
  [
    object.id,
    object.name,
    object.venue,
    object.positions,
    (val = object.date_start; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_end; "#{val.year}-#{val.month}-#{val.day}"),
    object.address,
    object.city,
    object.post_code,
    object.note_for_applicant,
    object.target_region_id,
    object.region_id,
    object.photo,
    object.directions,
    object.status,
    object.interview_type
  ]
end

def export_bulkinterviewevent_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::BulkInterviewEvent.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_bulkinterviewevent_object(object)
  [
    object.id,
    object.bulk_interview_id,
    object.event_id
  ]
end

def export_client_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Client.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_client_object(object)
  [
    object.id,
    object.active,
    object.name,
    object.company_type,
    object.address,
    object.phone_no,
    object.email,
    object.accountant_email,
    object.flair_contact,
    object.primary_client_contact_id,
    (val = object.terms_date_sent; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.terms_date_received; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.terms_client_contact_id,
    (val = object.safety_date_sent; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.safety_date_received; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.safety_client_contact_id,
    object.notes,
    object.invoice_notes
  ]
end

def export_clientcontact_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::ClientContact.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_clientcontact_object(object)
  [
    object.id,
    object.active,
    object.first_name,
    object.last_name,
    object.mobile_no,
    object.email,
    object.client_id,
    object.account_status
  ]
end

def export_event_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Event.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_event_object(object)
  [
    object.id,
    object.name,
    object.display_name,
    object.category_id,
    (val = object.date_start; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_end; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.public_date_start; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.public_date_end; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_callback_due; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.status,
    object.fullness,
    object.blurb_legacy,
    object.blurb_title,
    object.blurb_subtitle,
    object.blurb_opening,
    object.blurb_closing,
    object.blurb_job,
    object.blurb_shift,
    object.blurb_wage_additional,
    object.blurb_uniform,
    object.blurb_transport,
    object.leader_general,
    object.leader_meeting_location,
    object.leader_meeting_location_coords,
    object.leader_accomodation,
    object.leader_job_role,
    object.leader_arrival_time,
    object.leader_flair_phone_no,
    object.leader_handbooks,
    object.leader_staff_job_roles,
    object.leader_staff_arrival,
    object.leader_energy,
    object.leader_uniform,
    object.leader_food,
    object.leader_transport,
    object.leader_client_contact_id,
    object.location,
    object.address,
    object.post_code,
    object.region_id,
    object.website,
    object.notes,
    object.site_manager,
    object.office_manager_id,
    object.photo,
    object.show_in_history,
    object.show_in_public,
    object.show_in_home,
    object.show_in_payroll,
    object.show_in_time_clocking_app,
    object.remove_task,
    object.staff_needed,
    object.additional_staff,
    object.gigs_count,
    object.is_concert,
    object.jobs_description,
    object.accom_status,
    object.accom_hotel_name,
    object.accom_address,
    object.accom_phone,
    object.accom_parking,
    object.accom_total_cost,
    object.accom_booking_ref,
    object.accom_notes,
    object.accom_room_info,
    object.accom_distance,
    object.accom_booking_dates,
    object.accom_parking,
    object.accom_wifi,
    object.accom_cancellation_policy,
    object.accom_payment_method,
    object.accom_booked_by,
    object.accom_booking_dates,
    object.expense_notes,
    object.post_notes,
    object.default_job_id,
    object.default_location_id,
    object.default_assignment_id,
    object.require_training_ethics,
    object.require_training_customer_service,
    object.require_training_health_safety,
    object.require_training_sports,
    object.require_training_bar_hospitality,
    object.admin_completed,
    object.paid_breaks,
    object.show_in_ongoing,
    object.show_in_featured,
    object.show_in_planner,
    object.requires_booking,
    object.send_scheduled_to_work_auto_email,
    object.size_id,
    object.reviewed_by_manager,
    object.accom_booking_via,
    (val = object.accom_refund_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.is_restricted,
    object.has_bar,
    object.has_sport,
    object.has_hospitality,
    object.has_festivals,
    object.has_office,
    object.has_retail,
    object.has_warehouse,
    object.has_promotional,
    object.shift_start_time,
    object.featured_job,
    object.request_message,
    object.spares_message,
    object.applicants_message,
    object.action_message,
    object.other_info,
    object.created_at,
    object.senior_manager_id
  ]
end

def export_eventclient_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::EventClient.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_eventclient_object(object)
  [
    object.id,
    object.event_id,
    object.client_id
  ]
end

def export_eventdate_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::EventDate.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_eventdate_object(object)
  [
    object.id,
    object.event_id,
    (val = object.date; "#{val.year}-#{val.month}-#{val.day}"),
    object.tax_week_id
  ]
end

def export_eventsize_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::EventSize.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_eventsize_object(object)
  [
    object.id,
    object.name
  ]
end

def export_eventtask_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::EventTask.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_eventtask_object(object)
  [
    object.id,
    object.event_id,
    object.officer_id,
    object.second_officer_id,
    object.template_id,
    object.task,
    object.notes,
    (val = object.due_date; "#{val.year}-#{val.month}-#{val.day}"),
    object.completed,
    (val = object.completed_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.additional_notes,
    object.manager_notes,
    object.confirmed,
    object.tax_week_id,
    object.task_completed
  ]
end

def export_eventtasktemplate_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::EventTaskTemplate.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_eventtasktemplate_object(object)
  [
    object.id,
    object.task,
    object.notes
  ]
end

def export_expense_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Expense.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_expense_object(object)
  [
    object.id,
    object.name,
    object.event_id,
    object.cost,
    object.notes
  ]
end

def export_faqentry_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::FaqEntry.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_faqentry_object(object)
  [
    object.id,
    object.question,
    object.answer,
    object.position,
    object.topic
  ]
end

def export_gig_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Gig.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_gig_object(object)
  [
    object.id,
    object.event_id,
    object.prospect_id,
    object.job_id,
    object.location_id,
    object.notes,
    object.rating,
    object.status,
    object.miscellaneous_boolean,
    object.published
  ]
end

def export_gigassignment_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::GigAssignment.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_gigassignment_object(object)
  [
    object.id,
    object.gig_id,
    object.assignment_id
  ]
end

def export_gigrequest_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::GigRequest.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_gigrequest_object(object)
  [
    object.id,
    object.event_id,
    object.gig_id,
    object.prospect_id,
    object.created_at,
    object.spare,
    object.is_best,
    object.left_voice_message,
    object.email_status,
    object.texted,
    object.job_id,
    object.notes
  ]
end

def export_gigtag_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::GigTag.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_gigtag_object(object)
  [
    object.id,
    object.gig_id,
    object.tag_id
  ]
end

def export_gigtaxweek_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::GigTaxWeek.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_gigtaxweek_object(object)
  [
    object.id,
    object.gig_id,
    object.tax_week_id,
    object.assignment_email_type,
    object.assignment_email_template_id,
    object.confirmed
  ]
end

def export_interview_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Interview.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_interview_object(object)
  [
    object.id,
    object.interview_slot_id,
    object.interview_block_id,
    object.time_type,
    object.telephone_call_interview,
    object.video_call_interview,
    object.prospect_id
  ]
end

def export_interviewblock_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::InterviewBlock.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_interviewblock_object(object)
  [
    object.id,
    object.bulk_interview_id,
    (val = object.date; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.time_start; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    (val = object.time_end; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    object.slot_mins,
    object.number_of_applicants_per_slot,
    object.is_morning,
    object.morning_applicants,
    object.is_afternoon,
    object.afternoon_applicants,
    object.is_evening,
    object.evening_applicants,
    object.morning_interviews,
    object.afternoon_interviews,
    object.evening_interviews
  ]
end

def export_interviewslot_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::InterviewSlot.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_interviewslot_object(object)
  [
    object.id,
    object.interview_block_id,
    (val = object.time_start; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    (val = object.time_end; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    object.interviews_count
  ]
end

def export_invoice_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Invoice.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_invoice_object(object)
  [
    object.id,
    object.event_client_id,
    object.who,
    object.status,
    (val = object.date_emailed; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.tax_week_id
  ]
end

def export_job_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Job.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_job_object(object)
  [
    object.id,
    object.event_id,
    object.name,
    object.public_name,
    object.description,
    object.pay_17_and_under,
    object.pay_21_and_over,
    object.pay_18_and_over,
    object.pay_25_and_over,
    object.number_of_positions,
    object.shift_information,
    object.uniform_information,
    object.other_information,
    object.new_description,
    object.include_in_description
  ]
end

def export_libraryitem_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::LibraryItem.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_libraryitem_object(object)
  [
    object.id,
    object.name,
    object.filename
  ]
end

def export_location_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Location.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_location_object(object)
  [
    object.id,
    object.name,
    object.event_id,
    object.type
  ]
end

def export_logentry_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::LogEntry.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_logentry_object(object)
  [
    object.id,
    object.type,
    object.data
  ]
end

def export_officer_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Officer.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_officer_object(object)
  [
    object.id,
    object.first_name,
    object.last_name,
    object.email,
    object.role,
    object.active_operational_manager,
    object.senior_manager
  ]
end

def export_payweek_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::PayWeek.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_payweek_object(object)
  [
    object.id,
    object.job_id,
    object.event_id,
    object.prospect_id,
    object.tax_week_id,
    object.monday,
    object.tuesday,
    object.wednesday,
    object.thursday,
    object.friday,
    object.saturday,
    object.sunday,
    object.rate,
    object.deduction,
    object.allowance,
    object.status,
    object.type
  ]
end

def export_postarea_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::PostArea.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_postarea_object(object)
  [
    object.id,
    object.region_id,
    object.subcode,
    object.latitude,
    object.longitude
  ]
end

def export_prospect_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Prospect.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_prospect_object(object)
  [
    object.id,
    object.gender,
    object.status,
    object.client_id,
    object.email,
    object.first_name,
    object.last_name,
    (val = object.date_of_birth; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.nationality_id,
    object.country,
    object.address,
    object.address2,
    object.city,
    object.post_code,
    object.region_id,
    object.mobile_no,
    object.home_no,
    object.emergency_no,
    object.emergency_name,
    object.tax_choice,
    object.ni_number,
    object.bank_account_name,
    object.bank_sort_code,
    object.bank_account_no,
    object.bar_experience,
    object.bar_license_type,
    object.bar_license_no,
    object.bar_license_issued_by,
    (val = object.bar_license_expiry; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.training_type,
    !!object.datetime_agreement,
    object.id_number,
    object.visa_number,
    object.id_type,
    (val = object.id_expiry; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.visa_issue_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.visa_expiry; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.visa_indefinite,
    (val = object.id_sighted; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.notes,
    (val = object.created_at; "#{val.year}-#{val.month}-#{val.day}"),
    object.good_sport,
    object.good_bar,
    object.good_promo,
    object.good_hospitality,
    object.good_management,
    (val = object.date_start; val && "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_end; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.student_loan,
    object.applicant_status,
    object.rating,
    object.photo,
    object.has_large_photo,
    object.prefers_in_person,
    object.prefers_phone,
    object.prefers_skype,
    object.prefers_facetime,
    object.preferred_phone,
    object.preferred_skype,
    object.preferred_facetime,
    object.prefers_morning,
    object.prefers_afternoon,
    object.prefers_early_evening,
    object.prefers_midweek,
    object.prefers_weekend,
    object.performance_notes,
    object.manager_level,
    (val = object.last_login; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.training_ethics,
    object.training_customer_service,
    object.training_health_safety,
    object.training_sports,
    object.training_bar_hospitality,
    object.send_marketing_email,
    object.qualification_food_health_2,
    object.qualification_dbs,
    object.headquarter,
    (val = object.texted_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.email_status,
    (val = object.missed_interview_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.left_voice_message,
    object.flair_image,
    object.experienced,
    object.chatty,
    object.confident,
    object.language,
    object.big_teams,
    object.all_teams,
    object.prospect_character,
    object.team_notes,
    object.bespoke,
    object.flag_photo,
    object.cancelled_contracts,
    object.cancelled_eighteen_hrs_contracts,
    object.no_show_contracts,
    object.non_confirmed_contracts,
    object.held_spare_contracts,
    object.completed_contracts,
    object.dbs_certificate_number,
    (val = object.dbs_issue_date; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.has_bar_and_hospitality,
    object.has_sport_and_outdoor,
    object.has_promotional_and_street_marketing,
    object.has_merchandise_and_retail,
    object.has_reception_and_office_admin,
    object.has_festivals_and_concerts,
    object.has_bar_management_experience,
    object.has_staff_leadership_experience,
    object.has_hospitality_marketing,
    object.has_warehouse_marketing,
    object.warehouse_skill,
    object.hospitality_skill,
    object.bar_skill,
    object.sport_skill,
    object.festival_skill,
    object.office_skill,
    object.promo_skill,
    object.retail_skill,
    object.bar_manager_skill,
    object.staff_leader_skill,
    object.city_of_study,
    object.has_c19_test,
    object.is_clean,
    object.is_convicted,
    (val = object.c19_tt_at; val && "#{val.year}-#{val.month}-#{val.day}"),
    object.test_site_code,
    object.created_at,
    object.share_code,
    object.dbs_qualification_type,
    object.condition
  ]
end

def export_questionnaire_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Questionnaire.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_questionnaire_object(object)
  [
    object.id,
    object.prospect_id,
    object.enjoy_working_on_team,
    object.interested_in_bar,
    object.promotions_experience,
    object.retail_experience,
    object.interested_in_marshal,
    object.staff_leadership_experience,
    object.bar_management_experience,
    object.evening_shifts_work,
    object.day_shifts_work,
    object.weekends_work,
    object.week_days_work,
    object.contact_via_whatsapp,
    object.contact_via_text,
    object.contact_via_email,
    object.contact_via_telephone,
    object.scottish_personal_licence_qualification,
    object.dbs_qualification,
    object.food_health_level_two_qualification,
    object.english_personal_licence_qualification,
    object.has_bar_and_hospitality,
    object.has_sport_and_outdoor,
    object.has_promotional_and_street_marketing,
    object.has_merchandise_and_retail,
    object.has_reception_and_office_admin,
    object.has_festivals_and_concerts,
    object.team_leader_experience
  ]
end

def export_quoterequest_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::QuoteRequest.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_quoterequest_object(object)
  [
    object.id,
    object.name,
    object.company_name,
    object.telephone,
    object.email,
    object.contract_name,
    object.location,
    object.post_code,
    object.start_date,
    object.finish_date,
    object.job_position,
    object.full_range,
    object.number_of_people,
    object.wage_rates,
    object.other_facts
  ]
end

def export_region_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Region.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_region_object(object)
  [
    object.id,
    object.name
  ]
end

def export_shift_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Shift.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_shift_object(object)
  [
    object.id,
    object.event_id,
    object.tax_week_id,
    (val = object.date; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.time_start; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    (val = object.time_end; "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}")
  ]
end

def export_tag_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::Tag.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_tag_object(object)
  [
    object.id,
    object.name,
    object.event_id
  ]
end

def export_taxweek_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TaxWeek.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_taxweek_object(object)
  [
    object.id,
    (val = object.date_start; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_end; "#{val.year}-#{val.month}-#{val.day}"),
    object.tax_year_id,
    object.week
  ]
end

def export_taxyear_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TaxYear.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_taxyear_object(object)
  [
    object.id,
    (val = object.date_start; "#{val.year}-#{val.month}-#{val.day}"),
    (val = object.date_end; "#{val.year}-#{val.month}-#{val.day}")
  ]
end

def export_teamleaderrole_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TeamLeaderRole.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_teamleaderrole_object(object)
  [
    object.id,
    object.event_id,
    object.user_id,
    object.user_type,
    object.enabled
  ]
end

def export_textblock_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TextBlock.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_textblock_object(object)
  [
    object.id,
    object.key,
    object.type,
    object.title,
    object.status,
    object.thumbnail,
    object.updated_at,
    object.contents
  ]
end

def export_timeclockreport_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TimeClockReport.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_timeclockreport_object(object)
  [
    object.id,
    object.event_id,
    (val = object.date; "#{val.year}-#{val.month}-#{val.day}"),
    object.user_id,
    object.user_type,
    object.tax_week_id,
    object.status,
    object.notes,
    object.client_notes,
    object.client_rating,
    object.signed_by_name,
    object.signed_by_job_title,
    object.signed_by_company_name,
    object.signature,
    object.date_submitted
  ]
end

def export_timesheetentry_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::TimesheetEntry.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_timesheetentry_object(object)
  [
    object.id,
    object.gig_assignment_id,
    object.tax_week_id,
    (val = object.time_start; val && "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    (val = object.time_end; val && "#{val.hour.to_s.rjust(2, '0')}:#{val.min.to_s.rjust(2, '0')}"),
    object.break_minutes,
    object.status,
    object.rating,
    object.notes,
    object.invoiced,
    object.time_clock_report_id
  ]
end

def export_unworkedgigassignment_data_to_array(last_time = nil, get_confidential_data = true, buffer='')
  records = pg.exec(::Models::UnworkedGigAssignment.build_select(last_time, get_confidential_data))
  buffer << Oj.dump(records.values)
end

def export_unworkedgigassignment_object(object)
  [
    object.id,
    object.gig_id,
    object.assignment_id,
    object.reason
  ]
end

def export_all_data_to_hash(last_time = nil, get_confidential_data = true, buffer='')
  buffer << '{'
  buffer << '"accounts":'
  export_account_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"action_takens":'
  export_actiontaken_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"assignments":'
  export_assignment_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"assignment_email_templates":'
  export_assignmentemailtemplate_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"bookings":'
  export_booking_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"bulk_interviews":'
  export_bulkinterview_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"bulk_interview_events":'
  export_bulkinterviewevent_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"clients":'
  export_client_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"client_contacts":'
  export_clientcontact_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"events":'
  export_event_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"event_clients":'
  export_eventclient_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"event_dates":'
  export_eventdate_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"event_sizes":'
  export_eventsize_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"event_tasks":'
  export_eventtask_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"event_task_templates":'
  export_eventtasktemplate_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"expenses":'
  export_expense_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"faq_entries":'
  export_faqentry_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"gigs":'
  export_gig_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"gig_assignments":'
  export_gigassignment_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"gig_requests":'
  export_gigrequest_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"gig_tags":'
  export_gigtag_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"gig_tax_weeks":'
  export_gigtaxweek_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"interviews":'
  export_interview_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"interview_blocks":'
  export_interviewblock_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"interview_slots":'
  export_interviewslot_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"invoices":'
  export_invoice_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"jobs":'
  export_job_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"library_items":'
  export_libraryitem_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"locations":'
  export_location_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"admin_log_entries":'
  export_logentry_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"officers":'
  export_officer_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"pay_weeks":'
  export_payweek_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  if !last_time
  buffer << '"post_areas":'
  export_postarea_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  end
  buffer << '"prospects":'
  export_prospect_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"questionnaires":'
  export_questionnaire_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"quote_requests":'
  export_quoterequest_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"regions":'
  export_region_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"shifts":'
  export_shift_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"tags":'
  export_tag_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"tax_weeks":'
  export_taxweek_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"tax_years":'
  export_taxyear_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"team_leader_roles":'
  export_teamleaderrole_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"text_blocks":'
  export_textblock_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"time_clock_reports":'
  export_timeclockreport_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"timesheet_entries":'
  export_timesheetentry_data_to_array(last_time, get_confidential_data, buffer)
  buffer << ','
  buffer << '"unworked_gig_assignments":'
  export_unworkedgigassignment_data_to_array(last_time, get_confidential_data, buffer)
  buffer << '}'
end
end
