class AddCityOfStudyToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :city_of_study, :string
  end
end
