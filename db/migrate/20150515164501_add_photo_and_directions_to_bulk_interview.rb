class AddPhotoAndDirectionsToBulkInterview < ActiveRecord::Migration
  def up
    add_column :bulk_interviews, :photo, :string
    add_column :bulk_interviews, :directions, :text, :limit => nil
  end
  def down
    remove_column :bulk_interviews, :photo
    remove_column :bulk_interviews, :directions
  end
end
