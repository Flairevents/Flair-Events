class ChangesToPayrollDb < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE tax_weeks RENAME year TO tax_year"
    db.execute "ALTER TABLE tax_weeks ADD COLUMN status varchar(10) NOT NULL DEFAULT 'new'"
  end

  def down
    db.execute "ALTER TABLE tax_weeks RENAME tax_year TO year"
    db.execute "ALTER TABLE tax_weeks DROP COLUMN status"
  end
end