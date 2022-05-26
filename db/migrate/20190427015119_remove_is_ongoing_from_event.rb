class RemoveIsOngoingFromEvent < ActiveRecord::Migration[5.2]
  def change
    remove_column :events, :is_ongoing, :boolean, default: false, null: false
  end
end
