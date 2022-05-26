class AddTypeToLocation < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :type, :string, null: false, default: 'REGULAR'
  end
end
