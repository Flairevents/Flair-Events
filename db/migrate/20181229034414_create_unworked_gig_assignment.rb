class CreateUnworkedGigAssignment < ActiveRecord::Migration[5.2]
  def change
    create_table :unworked_gig_assignments do |t|
      t.references :gig, foreign_key: true, null: false
      t.references :assignment, foreign_key: true, null: false
      t.string :reason, null: false
      t.timestamps
    end
  end
end
