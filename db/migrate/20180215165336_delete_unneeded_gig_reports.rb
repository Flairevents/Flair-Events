class DeleteUnneededGigReports < ActiveRecord::Migration[5.1]
  def up
    Report.where(print_name: "Bar Exp/Training").destroy_all
    Report.where(print_name: "Applied - Bar Exp/Training").destroy_all
    Report.where(print_name: "Call List").destroy_all
    Report.where(print_name: "Peoples Details").destroy_all
  end
  def down
    Report.create!(name: 'bar_exp_training', print_name: 'Bar Exp/Training', table: 'gigs',
                   fields: ['name', 'email', 'date_of_birth', 'bar_experience', 'bar_license_type', 'bar_license_no', 'bar_license_expiry', 'training_type'],
                   row_numbers: true)
    Report.create!(name: 'gr_bar_exp_training', print_name: 'Applied - Bar Exp/Training', table: 'gig_requests',
                   fields: ['name', 'email', 'date_of_birth', 'bar_experience', 'bar_license_type', 'bar_license_no', 'bar_license_expiry', 'training_type'],
                   row_numbers: true)
    Report.create!(name: 'gigs_call_list',  print_name: 'Call List',       table: 'gigs',
                   fields: ['name', 'email', 'mobile_no', 'location', 'job_name', 'transport'])
    Report.create!(name: 'peoples_details', print_name: 'Peoples Details', table: 'gigs',
                   fields: ['name', 'mobile_no', 'home_no', 'email', 'bank_sort_code', 'bank_account_no', 'bank_name', 'location', 'transport'],
                   row_numbers: true)
  end
end
