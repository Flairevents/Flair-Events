class IndexTimeClockAndTimesheet < ActiveRecord::Migration[5.1]
  def change
    add_index :time_clocks, :updated_at
    add_index :timesheet_entries, :updated_at
    add_index :timesheet_entries, :pay_week_id
  end
end
