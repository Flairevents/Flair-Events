class AddPublishedToGigs < ActiveRecord::Migration[5.2]
  def change
    
    add_column :gigs, :published, :boolean, default: false

  end
end
