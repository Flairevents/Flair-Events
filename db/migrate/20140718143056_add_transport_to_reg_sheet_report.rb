class AddTransportToRegSheetReport < ActiveRecord::Migration
  def up
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'shift_times', 'location', 'transport', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'shift_times', 'location', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)
  end
end
