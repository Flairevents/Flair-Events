class AddIsManagerToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :is_manager, :boolean, null: false, default: false
  end
end
