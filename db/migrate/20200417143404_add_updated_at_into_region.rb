class AddUpdatedAtIntoRegion < ActiveRecord::Migration[5.2]
  def change
    add_column :regions, :updated_at,:datetime
  end
end
