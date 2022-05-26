class DropTimeClockTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :time_clocks 
  end
  def down
    create_table :time_clocks do |t|
      t.bigint  :timesheet_id
      t.bigint  :gig_assignment_id, null: false
      t.datetime :datetime_start
      t.datetime :datetime_end
      t.timestamps
    end
  end
end
