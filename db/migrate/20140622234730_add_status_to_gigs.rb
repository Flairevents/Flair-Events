class AddStatusToGigs < ActiveRecord::Migration
  def up
    add_column :gigs, :status, :string, null: false, default: 'Active'
  end
  def down
    remove_column :gigs, :status
  end
end
