class AddDefaultLocationToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :default_location_id, :integer, null: true, default: nil
  end
end
