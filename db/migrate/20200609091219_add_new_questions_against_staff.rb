class AddNewQuestionsAgainstStaff < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :has_sport_and_outdoor, :string
    add_column :questionnaires, :has_bar_and_hospitality, :string
    add_column :questionnaires, :has_festivals_and_concerts, :string
    add_column :questionnaires, :has_merchandise_and_retail, :string
    add_column :questionnaires, :has_promotional_and_street_marketing, :string
    add_column :questionnaires, :has_reception_and_office_admin, :string
  end
end
