class AddRequiredTrainingToEvent < ActiveRecord::Migration
  def change
    add_column :events, :require_training_ethics, :boolean, null: false, default: false
    add_column :events, :require_training_customer_service, :boolean, null: false, default: false
    add_column :events, :require_training_health_safety, :boolean, null: false, default: false
    add_column :events, :require_training_sports, :boolean, null: false, default: false
    add_column :events, :require_training_bar_hospitality, :boolean, null: false, default: false
  end
end
