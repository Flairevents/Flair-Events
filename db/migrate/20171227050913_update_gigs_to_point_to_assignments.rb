class UpdateGigsToPointToAssignments < ActiveRecord::Migration[5.1]
  def up
    Shift.reset_column_information
    Gig.all.each do |gig|
      ##### If there is a job or location, we will create an assignment
      job = Job.find_by_id(gig.job_id)
      location = Location.find_by_id(gig.location_id)
      if job || location then
        ##### If job is missing use a default one
        job ||= Job.where(event_id: gig.event_id, name: '?', type: 'Regular', pay_18_and_over: 0, pay_21_and_over: 0, pay_17_and_under: 0, pay_25_and_over: 0, include_in_description: false).first_or_create
        ##### If location is missing use a default one
        location ||= Location.where(event_id: gig.event_id, name: '?', staff_count: 0).first_or_create
        shift = Shift.where(event_id: gig.event.id).first || Shift.create(event_id: gig.event_id, time_start: DateTime.new(2000,1,1,1), time_end: DateTime.new(2000,1,1,2), date: gig.event.date_start, name: '*')
        assignment = Assignment.where(event_id: gig.event_id, job_id: job.id, shift_id: shift.id, location_id: location.id, staff_needed: 0).first_or_create
        GigAssignment.create(gig_id: gig.id, assignment_id: assignment.id)
      end
    end
  end
  def down
    GigAssignment.destroy_all 
  end
end
