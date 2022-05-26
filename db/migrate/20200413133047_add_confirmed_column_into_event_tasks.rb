class AddConfirmedColumnIntoEventTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :event_tasks, :confirmed, :boolean, null: false, default: false
  end
end
