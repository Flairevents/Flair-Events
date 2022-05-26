class RemoveClientFromEvent < ActiveRecord::Migration
  def change
    remove_column :events, :client, :string
  end
end
