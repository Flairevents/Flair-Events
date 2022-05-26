class AddQualificationFoodHealth2ToProspect < ActiveRecord::Migration[5.1]
  def change
    add_column :prospects, :qualification_food_health_2, :boolean, null: false, default: false
  end
end
