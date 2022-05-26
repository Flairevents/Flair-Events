class AddConditionToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :condition, :string
  end
end
