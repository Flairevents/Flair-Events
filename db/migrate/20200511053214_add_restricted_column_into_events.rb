class AddRestrictedColumnIntoEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :is_restricted, :boolean, null: false, default: false
  end
end
