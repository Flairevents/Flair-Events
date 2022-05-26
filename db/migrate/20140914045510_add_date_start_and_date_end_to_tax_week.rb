class AddDateStartAndDateEndToTaxWeek < ActiveRecord::Migration
  def up
    add_column :tax_weeks, :date_start, :date
    add_column :tax_weeks, :date_end, :date
  end
  def down
    remove_column :tax_weeks, :date_start
    remove_column :tax_weeks, :date_end
  end
end
