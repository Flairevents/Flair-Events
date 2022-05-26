class FixInvalidDefaultAssignmentForEvent < ActiveRecord::Migration[5.2]
  def up
    results = []
    Event.where('default_assignment_id IS NOT NULL').each do |event|
      assignment = Assignment.find_by_id(event.default_assignment_id)

      if !assignment || (assignment && assignment.event_id != event.id)
        results << "Reset default assignment for #{event.name}"
        event.default_assignment_id = nil
        event.save
      end
    end
    GigAssignment.includes(gig: [:event], assignment: [:event]).each do |gig_assignment|
      if gig_assignment.gig.event_id != gig_assignment.assignment.event_id
        results << "Destroy gig_assignment: #{gig_assignment.gig.event.name} vs #{gig_assignment.assignment.event.name}"
        gig_assignment.destroy
      end
    end
    results.uniq.each do |result|
      puts result
    end
    nil
  end
end
