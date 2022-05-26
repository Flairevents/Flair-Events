class AddHasLargePhotoToProspect < ActiveRecord::Migration[5.1]
  def change
    add_column :prospects, :has_large_photo, :boolean, null: false, default: false
  end
end
