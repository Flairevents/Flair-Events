class RemoveFeaturedFromJob < ActiveRecord::Migration[5.2]
  def change
    remove_column :jobs, :featured, :text
  end
end
