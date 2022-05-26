class UpdateTaxWeeksTaxWeekConstraint < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT IF EXISTS tax_weeks_tax_week_check"
    db.execute "ALTER TABLE tax_weeks ADD CONSTRAINT tax_weeks_tax_week_check CHECK (tax_week > 0 AND tax_week <= 53)"
  end

  def down
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT IF EXISTS tax_weeks_tax_week_check"
    db.execute "ALTER TABLE tax_weeks ADD CONSTRAINT tax_weeks_tax_week_check CHECK (tax_week > 0 AND tax_week <= 52)"
  end
end
