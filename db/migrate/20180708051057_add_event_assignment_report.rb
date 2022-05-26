class AddEventAssignmentReport < ActiveRecord::Migration[5.1]
  def up
    Report.create!(name: 'event_assignments', print_name: 'Event Assignments', table: 'assignments',
                   fields: ['job_name', 'date', 'shift_start', 'shift_end', 'location', 'staff_assigned', 'staff_needed'],
                   row_numbers: false)
  end
  def down
    Report.where(name: 'event_assignments').destroy_all
  end
end
