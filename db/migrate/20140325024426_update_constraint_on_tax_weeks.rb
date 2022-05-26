class UpdateConstraintOnTaxWeeks < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT IF EXISTS tax_weeks_check1"
    db.execute "ALTER TABLE tax_weeks ADD CONSTRAINT tax_weeks_check1 CHECK (rate >= 0 AND deduction >= 0 AND allowance >= 0)"
  end

  def down
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT IF EXISTS tax_weeks_check1"
    db.execute "ALTER TABLE tax_weeks ADD CONSTRAINT tax_weeks_check1 CHECK (rate > 0 AND deduction >= 0 AND allowance >= 0)"
  end
end
