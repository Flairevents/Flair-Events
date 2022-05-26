class CreateTimeClocks < ActiveRecord::Migration[5.1]
  def change
    create_table :time_clocks do |t|
      t.integer  :timesheet_id
      t.integer  :gig_assignment_id, null: false
      t.datetime :datetime_start
      t.datetime :datetime_end
      t.timestamps
    end
  end
end
