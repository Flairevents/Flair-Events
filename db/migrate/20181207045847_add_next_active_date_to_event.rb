class AddNextActiveDateToEvent < ActiveRecord::Migration[5.2]
  def up
    add_column :events, :next_active_date, :date 
  end
  def down
    remove_column :events, :next_active_date, :date
  end
end
