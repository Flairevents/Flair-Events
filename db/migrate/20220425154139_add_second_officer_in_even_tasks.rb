class AddSecondOfficerInEvenTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :event_tasks, :second_officer_id, :integer
  end
end
