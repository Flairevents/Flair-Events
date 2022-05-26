class AddQualificationNameAndCityOfStudyToQuestionnaire < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :qualification_name, :string
    add_column :questionnaires, :city_of_study, :string
  end
end
