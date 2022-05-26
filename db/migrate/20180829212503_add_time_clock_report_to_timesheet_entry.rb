class AddTimeClockReportToTimesheetEntry < ActiveRecord::Migration[5.2]
  def change
    add_column :timesheet_entries, :time_clock_report_id, :integer
  end
end
