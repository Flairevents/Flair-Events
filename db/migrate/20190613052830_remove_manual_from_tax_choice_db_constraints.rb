class RemoveManualFromTaxChoiceDbConstraints < ActiveRecord::Migration[5.2]
  def up
    execute "ALTER TABLE prospects DROP CONSTRAINT prospects_tax_choice_check"
    execute "ALTER TABLE prospects ADD CHECK (tax_choice IS NULL OR tax_choice IN ('A', 'B', 'C'))"
  end
  def down
    execute "ALTER TABLE prospects DROP CONSTRAINT prospects_tax_choice_check"
    execute "ALTER TABLE prospects ADD CHECK (tax_choice IS NULL OR tax_choice IN ('A', 'B', 'C', 'Manual'))"
  end
end
