class AddTaskCompletedIntoEventTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :event_tasks, :task_completed, :boolean, null: false, default: false
  end
end
