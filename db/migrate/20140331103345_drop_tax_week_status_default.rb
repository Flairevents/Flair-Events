class DropTaxWeekStatusDefault < ActiveRecord::Migration
  def up
     db.execute "ALTER TABLE tax_weeks ALTER COLUMN tax_week DROP DEFAULT"
  end

  def down
     db.execute "ALTER TABLE tax_weeks ALTER COLUMN tax_week ADD DEFAULT 'new'"
  end
end
