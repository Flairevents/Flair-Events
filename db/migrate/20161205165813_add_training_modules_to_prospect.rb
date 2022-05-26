class AddTrainingModulesToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :training_ethics, :boolean, null: false, default: false
    add_column :prospects, :training_customer_service, :boolean, null: false, default: false
    add_column :prospects, :training_health_safety, :boolean, null: false, default: false
    add_column :prospects, :training_sports, :boolean, null: false, default: false
    add_column :prospects, :training_bar_hospitality, :boolean, null: false, default: false
  end
end
