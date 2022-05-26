class LinkPostAreasToRegions < ActiveRecord::Migration[5.2]
  # Our data is linked from PostArea -> PostRegion -> Region
  # However, in most cases, the PostRegions aren't used for anything but as a join table
  #   from PostArea -> Region
  # It will be faster to retrieve Regions if we have a direct link from PostArea
  # The data never changes, so there won't be problems with updating links
  def change
    add_column :post_areas, :region_id, :integer
    PostArea.all.each do |post_area|
      post_area.region_id = post_area.post_region.region_id
      post_area.save!
    end
    change_column_null :post_areas, :region_id, false
  end
end
