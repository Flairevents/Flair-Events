class ResetManualTaxChoice < ActiveRecord::Migration[5.2]
  def up
    Prospect.where(tax_choice: 'Manual').update_all(tax_choice: nil)
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
