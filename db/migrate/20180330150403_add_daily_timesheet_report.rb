class AddDailyTimesheetReport < ActiveRecord::Migration[5.1]
  def up 
    Report.create!(name: 'timesheet_breakdown_daily', print_name: 'Timesheet Breakdown (Daily)', table: 'timesheet_entries',
                   fields: ['name', 'job', 'time_start', 'time_end', 'total_hours', 'break_minutes', 'net_hours', 'location', 'date'],
                   row_numbers: true, worksheet_key: 'date')
  end
  def down
    Report.where(name: 'timesheet_breakdown_daily', table: 'timesheet_entries').destroy_all
  end
end
