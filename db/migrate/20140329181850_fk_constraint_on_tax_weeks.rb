class FkConstraintOnTaxWeeks < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE tax_weeks ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
  end

  def down
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT tax_weeks_prospect_id_fkey"
  end
end
