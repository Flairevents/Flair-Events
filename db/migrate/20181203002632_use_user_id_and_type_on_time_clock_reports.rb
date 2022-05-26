class UseUserIdAndTypeOnTimeClockReports < ActiveRecord::Migration[5.2]
  def up
    remove_index :time_clock_reports, name: 'index_time_clock_reports_on_event_date_submitted_by'
    add_column :time_clock_reports, :user_id, :bigint
    add_column :time_clock_reports, :user_type, :string
    ##### Currently only employees can submit time-clocking reports,
    ##### so assume that existing are for employees
    TimeClockReport.all.each do |time_clock_report|
      prospect = Prospect.where(email: time_clock_report.submitted_by_email).first
      time_clock_report.user_id = prospect.id
      time_clock_report.user_type = 'Prospect'
      time_clock_report.save!
    end
    change_column_null :time_clock_reports, :user_id, false
    change_column_null :time_clock_reports, :user_type, false
    remove_column :time_clock_reports, :submitted_by_email
    add_index :time_clock_reports, [:event_id, :date, :user_type, :user_id], unique: true, name: 'index_time_clock_reports_on_event_date_user'
  end
  def down
    remove_index :time_clock_reports, name: 'index_time_clock_reports_on_event_date_user'
    add_column :time_clock_reports, :submitted_by_email, :string
    ##### Currently only employees can submit time-clocking reports,
    ##### so assume that existing are for employees
    TimeClockReport.all.each do |time_clock_report|
      prospect = Prospect.find(time_clock_report.user_id)
      time_clock_report.submitted_by_email = prospect.email
      time_clock_report.save!
    end
    change_column_null :time_clock_reports, :submitted_by_email, false
    remove_column :time_clock_reports, :user_id
    remove_column :time_clock_reports, :user_type
    add_index :time_clock_reports, [:event_id, :date, :submitted_by_email], unique: true, name: 'index_time_clock_reports_on_event_date_submitted_by'
  end
end
