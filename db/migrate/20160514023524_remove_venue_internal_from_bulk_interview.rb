class RemoveVenueInternalFromBulkInterview < ActiveRecord::Migration
  def up
    remove_column :bulk_interviews, :venue_internal
  end
  def down
    add_column :bulk_interviews, :venue_internal, :string
  end
end
