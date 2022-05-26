class AddActiveAndDateEndAndDateInactiveToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :active, :boolean
    add_column :prospects, :date_end, :date
    add_column :prospects, :date_inactive, :date
  end
  def down
    remove_column :prospects, :active
    remove_column :prospects, :date_end
    remove_column :prospects, :date_inactive
  end
end
