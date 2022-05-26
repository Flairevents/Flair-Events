class RemoveBlockedFromProspect < ActiveRecord::Migration
  def change
    remove_column :prospects, :blocked
  end
end
