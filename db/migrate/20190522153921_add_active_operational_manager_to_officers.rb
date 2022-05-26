class AddActiveOperationalManagerToOfficers < ActiveRecord::Migration[5.2]
  def change
    add_column :officers, :active_operational_manager, :boolean, default: false, null: false
  end
end
