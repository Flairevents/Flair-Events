class RemoveTaxCodeOnProspects < ActiveRecord::Migration[5.2]
  def change
    remove_column :prospects, :tax_code, :string
  end
end
