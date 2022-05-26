class CreateClientsReport < ActiveRecord::Migration
  def up
    Report.create!(name: 'client_details', print_name: 'Client Details', table: 'clients', row_numbers: true,
                   fields: ['active', 'name', 'address', 'phone_no', 'email', 'primary_contact_name', 'primary_contact_mobile_no', 'primary_contact_email', 'notes'])
  end
  def down
    Report.where(name: 'client_details', table: 'tax_weeks').destroy_all
  end
end
