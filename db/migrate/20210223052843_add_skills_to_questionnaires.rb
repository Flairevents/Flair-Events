class AddSkillsToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :skills, :string, default: nil
  end
end
