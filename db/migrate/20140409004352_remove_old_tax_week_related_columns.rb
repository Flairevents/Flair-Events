class RemoveOldTaxWeekRelatedColumns < ActiveRecord::Migration
  def up
    remove_column :events, :exported_tax_weeks
  end

  def down
    add_column :events, :exported_tax_weeks, :boolean, null: false, default: true
  end
end
