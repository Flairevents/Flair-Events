class AddNotesIntoGigRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :gig_requests, :notes, :text, default: '', null: false
  end
end
