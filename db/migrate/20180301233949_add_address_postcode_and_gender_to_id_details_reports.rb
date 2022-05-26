class AddAddressPostcodeAndGenderToIdDetailsReports < ActiveRecord::Migration[5.1]
  def up
    Report.where(name: 'id_details', table: 'gigs').destroy_all
    Report.create!(name: 'id_details', print_name: 'ID Details', table: 'gigs',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality', 'address', 'post_code', 'gender'],
                   row_numbers: true)
    Report.where(name: 'gr_id_details', table: 'gig_requests').destroy_all
    Report.create!(name: 'gr_id_details', print_name: 'Applied - ID Details', table: 'gig_requests',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality', 'address', 'post_code', 'gender'],
                   row_numbers: true)
  end
  def down 
    Report.where(name: 'id_details', table: 'gigs').destroy_all
    Report.create!(name: 'id_details', print_name: 'ID Details', table: 'gigs',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality'],
                   row_numbers: true)
    Report.where(name: 'gr_id_details', table: 'gig_requests').destroy_all
    Report.create!(name: 'gr_id_details', print_name: 'Applied - ID Details', table: 'gig_requests',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality'],
                   row_numbers: true)
  end
end
