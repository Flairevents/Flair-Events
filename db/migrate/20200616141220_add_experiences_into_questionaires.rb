class AddExperiencesIntoQuestionaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :bar_management_experience, :boolean
    add_column :questionnaires, :staff_leadership_experience, :boolean
  end
end
