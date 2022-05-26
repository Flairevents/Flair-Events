class RenamePendingToSpareOnGigRequests < ActiveRecord::Migration[5.2]
  def change
    rename_column :gig_requests, :pending, :spare
  end
end
