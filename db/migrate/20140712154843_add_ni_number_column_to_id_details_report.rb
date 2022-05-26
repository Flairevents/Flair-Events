class AddNiNumberColumnToIdDetailsReport < ActiveRecord::Migration
  def up
    Report.where(name: 'id_details', table: 'gigs').destroy_all
    Report.create!(name: 'id_details', print_name: 'ID Details', table: 'gigs',
                   fields: ['name', 'date_of_birth', 'ni_number', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'id_details', table: 'gigs').destroy_all
    Report.create!(name: 'id_details', print_name: 'ID Details', table: 'gigs',
                   fields: ['name', 'date_of_birth', 'id_type', 'id_number', 'visa_number', 'visa_expiry', 'nationality'],
                   row_numbers: true)
  end
end
