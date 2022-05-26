class CreateEventTaskTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :event_task_templates do |t|
      t.string :task, null: false, unique: true
      t.text :notes, default: '', null: false
      t.timestamps null: false
    end
  end
end
