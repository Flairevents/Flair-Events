class AddNewExperiencesInProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :has_festival_event_bar_management_experience, :boolean, default: false, null: false
    add_column :prospects, :has_event_production_experience, :boolean, default: false, null: false
  end
end
