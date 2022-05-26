class RemoveIsManagerFromProspect < ActiveRecord::Migration
  def change
    remove_column :prospects, :is_manager
  end
end
