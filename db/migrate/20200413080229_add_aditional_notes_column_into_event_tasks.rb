class AddAditionalNotesColumnIntoEventTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :event_tasks, :additional_notes, :string
  end
end
