class AddNullConstraintsToColumns < ActiveRecord::Migration[5.2]
  def change
    # Some columns are not allowed to be null (Rails model checks for that),
    #   but it was not enforced in DB
    # It's better to be strict about what is allowed into the DB

    change_column_null :assignment_email_templates, :event_id, false

    change_column_null :bookings, :event_client_id,       false

    change_column_null :bulk_interviews, :name,           false
    change_column_null :bulk_interviews, :date_start,     false
    change_column_null :bulk_interviews, :date_end,       false
    change_column_null :bulk_interviews, :interview_type, false
    change_column_null :bulk_interviews, :venue,          false
    change_column_null :bulk_interviews, :status,         false

    change_column_null :bulk_interview_events, :bulk_interview_id, false
    change_column_null :bulk_interview_events, :event_id,          false

    change_column_null :change_requests, :prospect_id, false

    change_column_null :clients,         :name,        false

    change_column_null :client_contacts, :client_id,   false
    change_column_null :client_contacts, :first_name,  false
    change_column_null :client_contacts, :last_name,   false
    change_column_null :client_contacts, :email,       false

    change_column_null :event_clients,   :event_id,    false
    change_column_null :event_clients,   :client_id,   false

    change_column_null :events, :date_start,                 false
    change_column_null :events, :date_end,                   false
    change_column_null :events, :fullness,                   false
    change_column_null :events, :accom_status,               false
    change_column_null :events, :invoice_frequency_in_weeks, false
    change_column_null :events, :is_ongoing,                 false
    change_column_null :events, :show_in_public,             false

    change_column_null :faq_entries,     :topic,       false

    change_column_null :gig_tags,        :gig_id,      false
    change_column_null :gig_tags,        :tag_id,      false

    change_column_null :gig_tax_weeks,   :gig_id,      false
    change_column_null :gig_tax_weeks,   :tax_week_id, false

    change_column_null :interviews,      :prospect_id,       false
    change_column_null :interviews,      :interview_slot_id, false

    change_column_null :interview_blocks, :date,                          false
    change_column_null :interview_blocks, :time_start,                    false
    change_column_null :interview_blocks, :time_end,                      false
    change_column_null :interview_blocks, :slot_mins,                     false
    change_column_null :interview_blocks, :number_of_applicants_per_slot, false

    change_column_null :interview_slots,  :time_start, false
    change_column_null :interview_slots,  :time_end,   false

    change_column_null :invoices, :event_client_id,    false
    change_column_null :invoices, :tax_week_id,        false
    change_column_null :invoices, :status,             false

    change_column_null :prospects, :prefers_phone,     false
    change_column_null :prospects, :prefers_skype,     false
    change_column_null :prospects, :prefers_facetime,  false
    change_column_null :prospects, :prefers_in_person, false

    change_column_null :tax_weeks, :tax_year_id,       false
    change_column_null :tax_weeks, :week,              false
    change_column_null :tax_weeks, :date_start,        false
    change_column_null :tax_weeks, :date_end,          false

    change_column_null :tax_years, :date_start,        false
    change_column_null :tax_years, :date_end,          false

    change_column_null :time_clock_reports, :event_id, false
    change_column_null :time_clock_reports, :date,     false
    change_column_null :time_clock_reports, :status,   false
    change_column_null :time_clock_reports, :submitted_by_email, false

    change_column_null :timesheet_entries,  :status,   false
  end
end
