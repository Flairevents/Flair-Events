class AddNewExperiencesInQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :festival_event_bar_management_experience, :boolean
    add_column :questionnaires, :event_production_experience, :boolean
  end
end
