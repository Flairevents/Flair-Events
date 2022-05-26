class RemoveTasksForEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :remove_task, :boolean
  end
end
