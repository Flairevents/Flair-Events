class AddShowInFeaturedToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :show_in_featured, :boolean, default: false, null: false
  end
end
