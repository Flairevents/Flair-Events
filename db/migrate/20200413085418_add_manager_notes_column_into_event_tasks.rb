class AddManagerNotesColumnIntoEventTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :event_tasks, :manager_notes, :string
  end
end
