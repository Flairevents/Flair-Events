class CreateRegSheetDailyReport < ActiveRecord::Migration[5.1]
  def up
    Report.create!(name: 'reg_sheet_daily', print_name: 'Reg Sheet (Daily)', table: 'gigs',
                   fields: ['name', 'job_name', 'date', 'shift_times', 'location', 'tag', 'notes'],
                   row_numbers: true,
                   worksheet_key: 'date')

  end
  def down
    Report.where(name: 'reg_sheet_daily', table: 'gigs').destroy_all
  end
end
