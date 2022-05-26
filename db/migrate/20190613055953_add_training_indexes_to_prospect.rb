class AddTrainingIndexesToProspect < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :training_ethics_index,           :integer, default: 0, null: false
    add_column :prospects, :training_customer_service_index, :integer, default: 0, null: false
    add_column :prospects, :training_health_safety_index,    :integer, default: 0, null: false
    add_column :prospects, :training_sports_index,           :integer, default: 0, null: false
    add_column :prospects, :training_bar_hospitality_index,  :integer, default: 0, null: false
  end
end
