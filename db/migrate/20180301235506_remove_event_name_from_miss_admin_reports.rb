class RemoveEventNameFromMissAdminReports < ActiveRecord::Migration[5.1]
  def up
    Report.where(name: 'missing_details', table: 'gigs').destroy_all
    Report.create!(name: 'missing_details', print_name: 'Miss Admin', table: 'gigs',
                   fields: ['first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
    Report.where(name: 'gr_missing_details', table: 'gig_requests').destroy_all
    Report.create!(name: 'gr_missing_details', print_name: 'Applied - Miss Admin', table: 'gig_requests',
                   fields: ['first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
  end
  def down
    Report.where(name: 'missing_details', table: 'gigs').destroy_all
    Report.create!(name: 'missing_details', print_name: 'Miss Admin', table: 'gigs',
                   fields: ['event_name', 'first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
    Report.where(name: 'gr_missing_details', table: 'gig_requests').destroy_all
    Report.create!(name: 'gr_missing_details', print_name: 'Applied - Miss Admin', table: 'gig_requests',
                   fields: ['event_name', 'first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
  end
end
