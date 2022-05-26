class UpdateLocationIndex < ActiveRecord::Migration[5.1]
  def up
    remove_index :locations, [:event_id, :name]
    add_index :locations, [:event_id, :name, :type], unique: true
  end
  def down 
    remove_index :locations, [:event_id, :name, :status]
    add_index :locations, [:event_id, :name, :type]
  end
end
