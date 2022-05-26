class CreateEventTaskReport < ActiveRecord::Migration[5.2]
  def up 
    Report.create!(name: 'event_tasks', print_name: 'Event Task List', table: 'event_tasks',
                   fields: ['due_date', 'event_name', 'completed', 'task', 'notes', 'office_manager'],
                   row_numbers: false)
  end
  def down
    Report.where(name: 'event_tasks', table: 'event_tasks').destroy_all
  end
end
