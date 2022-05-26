class ChangeDefaultJobToDefaultAssignment < ActiveRecord::Migration[5.1]
  def up
    add_column :events, :default_assignment_id, :integer
    Event.all.each do |event|
      if event.default_job_id
        location = Location.where(event_id: event.id, name: '?').first_or_create
        shift = Shift.where(event_id: event.id, time_start: DateTime.new(2000,1,1,1), time_end: DateTime.new(2000,1,1,2), date: event.date_start, name: '*').first_or_create
        assignment = Assignment.where(event_id: event.id, job_id: event.default_job_id, shift_id: shift.id, location_id: location.id).first_or_create 
        event.default_assignment_id = assignment.id
        event.save!
      end
    end
    remove_column :events, :default_job_id
  end
  def down
    add_column :events, :default_job_id, :integer
    Event.all.each do |event|
      if event.default_assignment_id
        event.default_job_id = Assignment.find(event.default_assignment_id).job_id
        event.save!
      end
    end
    remove_column :events, :default_assignment_id
  end
end
