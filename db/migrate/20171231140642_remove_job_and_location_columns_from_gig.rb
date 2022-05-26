class RemoveJobAndLocationColumnsFromGig < ActiveRecord::Migration[5.1]
  def change
    remove_column :gigs, :job_id, :integer
    remove_column :gigs, :location_id, :integer
  end
end
