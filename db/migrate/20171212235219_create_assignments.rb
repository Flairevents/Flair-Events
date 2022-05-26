class CreateAssignments < ActiveRecord::Migration[5.1]
  def change
    create_table :assignments do |t|
      t.integer :event_id, null: false
      t.integer :job_id, null: false
      t.integer :shift_id, null: false
      t.integer :location_id, null: false
      t.integer :staff_needed, null: false
      t.integer :staff_count, null: false, default: 0
      t.timestamps null: false
    end
  end
end
