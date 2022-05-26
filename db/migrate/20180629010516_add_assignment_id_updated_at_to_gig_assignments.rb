class AddAssignmentIdUpdatedAtToGigAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :gig_assignments, :assignment_id_updated_at, :datetime
    GigAssignment.all.each do |gig_assignment|
      gig_assignment.update_column(:assignment_id_updated_at, gig_assignment.updated_at)
    end 
  end
end
