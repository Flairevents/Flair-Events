class AddTimesheetReport < ActiveRecord::Migration[5.1]
  def up 
    Report.create!(name: 'timesheet_breakdown', print_name: 'Timesheet Breakdown', table: 'timesheet_entries',
                   fields: ['name', 'job', 'time_start', 'time_end', 'total_hours', 'break_minutes', 'net_hours', 'location', 'date'],
                   row_numbers: true)
  end
  def down
    Report.where(name: 'timesheet_breakdown', table: 'timesheet_entries').destroy_all
  end
end
