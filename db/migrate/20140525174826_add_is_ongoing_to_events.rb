class AddIsOngoingToEvents < ActiveRecord::Migration
  def up 
    add_column :events, :is_ongoing, :boolean
  end
  def down
    remove_column :events, :is_ongoing
  end
end
