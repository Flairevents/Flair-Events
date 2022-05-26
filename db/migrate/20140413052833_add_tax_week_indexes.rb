class AddTaxWeekIndexes < ActiveRecord::Migration
  def up
    db.execute('DROP INDEX index_tax_weeks_on_year_and_tax_week')
    add_index :tax_weeks, :status
    add_index :tax_weeks, :tax_year
    add_index :tax_weeks, [:status, :tax_year, :tax_week, :gig_id]
    add_index :tax_weeks, [:status, :tax_year, :tax_week]
  end

  def down
    add_index :tax_weeks, [:tax_year, :tax_week]
    remove_index :tax_weeks, :status
    remove_index :tax_weeks, :tax_year
    remove_index :tax_weeks, [:status, :tax_year, :tax_week, :gig_id]
    remove_index :tax_weeks, [:status, :tax_year, :tax_week]
  end
end