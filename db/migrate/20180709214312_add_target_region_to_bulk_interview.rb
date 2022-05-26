class AddTargetRegionToBulkInterview < ActiveRecord::Migration[5.1]
  ##### region is already a virtual attribute in lib/has_post_code.rb,
  ##### our region has to have a different name so that activerecord
  ##### can associate it properly
  def up
    add_column :bulk_interviews, :target_region_id, :integer
    BulkInterview.all.each do |bi|
      bi.update_column(:target_region_id, bi.region_id)
    end 
    remove_column :bulk_interviews, :region_id
  end 
  def down
    add_column :bulk_interviews, :region_id, :integer
    BulkInterview.all.each do |bi|
      bi.update_column(:region_id, bi.target_region_id)
    end 
    remove_column :bulk_interviews, :target_region_id
  end
end
