class CreateTimesheetEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :timesheet_entries do |t|
      t.integer  :gig_assignment_id, null: false
      t.integer  :tax_week_id, null: false
      t.integer  :pay_week_id
      t.time     :time_start
      t.time     :time_end
      t.integer  :break_minutes
      t.string   :status
      t.integer  :rating
      t.text     :notes
      t.timestamps
    end
  end
end
