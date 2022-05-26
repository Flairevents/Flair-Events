class AddGigAssignmentsJoinsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :gig_assignments do |t|
      t.belongs_to :gig, index: true, null: false
      t.belongs_to :assignment, index: true, null: false
      t.timestamps null: false
    end
    add_index :gig_assignments, [:gig_id, :assignment_id], unique: true
  end
end
