class AddMissAdminReport < ActiveRecord::Migration
  def up
    Report.create!(name: 'missing_details', print_name: 'Miss Admin', table: 'gigs',
                   fields: ['event_name', 'first_name', 'last_name', 'has_dob', 'has_tax', 'has_bank', 'has_ni', 'has_id', 'mobile_no', 'email'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'missing_details', print_name: 'Miss Admin', table: 'gigs').destroy_all
  end
end
