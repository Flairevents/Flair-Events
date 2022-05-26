class AddSkillsIntoEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :has_bar, :boolean, default: false, null: false
    add_column :events, :has_sport, :boolean, default: false, null: false
    add_column :events, :has_hospitality, :boolean, default: false, null: false
    add_column :events, :has_festivals, :boolean, default: false, null: false
    add_column :events, :has_office, :boolean, default: false, null: false
    add_column :events, :has_retail, :boolean, default: false, null: false
    add_column :events, :has_warehouse, :boolean, default: false, null: false
    add_column :events, :has_promotional, :boolean, default: false, null: false
  end
end
