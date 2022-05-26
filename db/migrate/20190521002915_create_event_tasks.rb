class CreateEventTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :event_tasks do |t|
      t.bigint :event_id
      t.bigint :officer_id,       null: false
      t.bigint :template_id
      t.string     :task,      null: false, default: ''
      t.text       :notes,     null: false, default: ''
      t.date       :due_date,  null: false
      t.boolean    :completed, null: false, default: false
      t.timestamps
    end
  end
end
