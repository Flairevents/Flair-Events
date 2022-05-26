class AddBestColumnIntoRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :gig_requests, :is_best, :boolean, null: false, default: false
  end
end
