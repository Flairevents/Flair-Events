class AddRegionIdAndVenueInternalToBulkInterview < ActiveRecord::Migration
  def up
    add_column :bulk_interviews, :region_id, :integer
    add_column :bulk_interviews, :venue_internal, :string
  end
  def down
    remove_column :bulk_interviews, :region_id
    remove_column :bulk_interviews, :venue_internal
  end
end
