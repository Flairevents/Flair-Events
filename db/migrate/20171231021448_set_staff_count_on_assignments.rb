class SetStaffCountOnAssignments < ActiveRecord::Migration[5.1]
  def up
    Assignment.all.each do |assignment|
      assignment.staff_count = GigAssignment.where(assignment_id: assignment.id).length
      assignment.save
    end
  end
  def down
    Assignment.update_all(staff_count: 0)
  end
end
