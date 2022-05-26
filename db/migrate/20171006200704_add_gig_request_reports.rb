class AddGigRequestReports < ActiveRecord::Migration[5.1]
  def up
    Report.create!(name: 'gr_missing_details', print_name: 'Applied - Miss Admin', table: 'gig_requests',
                   fields: ['event_name', 'first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
    Report.create!(name: 'gr_id_details', print_name: 'Applied - ID Details', table: 'gig_requests',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality'],
                   row_numbers: true)
    Report.create!(name: 'gr_bar_exp_training', print_name: 'Applied - Bar Exp/Training', table: 'gig_requests',
                   fields: ['name', 'email', 'date_of_birth', 'bar_experience', 'bar_license_type', 'bar_license_no', 'bar_license_expiry', 'training_type'],
                   row_numbers: true)
    Report.create!(name: 'gr_tel_no', print_name: 'Applied - Tel List', table: 'gig_requests',
                   fields: ['name', 'home_no', 'mobile_no', 'emergency_no'],
                   row_numbers: true)
  end
  def down
    Report.where(name: ['gr_missing_details', 'gr_id_details', 'gr_bar_exp_training', 'gr_tel_no']).destroy_all
  end
end
