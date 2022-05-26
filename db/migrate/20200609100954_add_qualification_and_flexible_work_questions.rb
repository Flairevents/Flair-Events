class AddQualificationAndFlexibleWorkQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :dbs_qualification, :string
    add_column :questionnaires, :food_health_level_two_qualification, :string
    add_column :questionnaires, :english_personal_licence_qualification, :string
    add_column :questionnaires, :scottish_personal_licence_qualification, :string

    add_column :questionnaires, :week_days_work, :string
    add_column :questionnaires, :weekends_work, :string
    add_column :questionnaires, :day_shifts_work, :string
    add_column :questionnaires, :evening_shifts_work, :string

  end
end
