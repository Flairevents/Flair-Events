class AddSkillsAndMarketingColumnsInTheProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :hospitality_skill, :string
    add_column :prospects, :warehouse_skill, :string

    add_column :prospects, :has_hospitality_marketing, :boolean, default: false, null: false
    add_column :prospects, :has_warehouse_marketing, :boolean, default: false, null: false
  end
end
