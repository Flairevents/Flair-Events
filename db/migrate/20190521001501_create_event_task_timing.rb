class CreateEventTaskTiming < ActiveRecord::Migration[5.2]
  def change
    create_table :event_task_timings do |t|
      t.references :template, foreign_key: { to_table: :event_task_templates }, null: false, index: false
      t.references :size, foreign_key: { to_table: :event_sizes }, null: false, index: false
      t.string     :type, null: false
      t.integer    :days, null: false
      t.timestamps
    end
    add_index :event_task_timings, [:size_id, :type]
  end
end
