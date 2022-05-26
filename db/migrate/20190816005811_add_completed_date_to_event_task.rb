class AddCompletedDateToEventTask < ActiveRecord::Migration[5.2]
  def up
    add_column :event_tasks, :completed_date, :date
    EventTask.all.each do |event_task|
      event_task.completed_date = event_task.updated_at if event_task.completed
      event_task.save!
    end
  end
  def down
    remove_column :event_tasks, :completed_date
  end
end
