class AddBlockedToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :blocked, :boolean, null: false, default: false
  end
end
