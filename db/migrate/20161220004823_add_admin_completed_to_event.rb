class AddAdminCompletedToEvent < ActiveRecord::Migration
  def change
    add_column :events, :admin_completed, :boolean, null: false, default: false
  end
end
