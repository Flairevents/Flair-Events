class ChangeColumnDatatypesIntoQuestionnaires < ActiveRecord::Migration[5.2]
  def up
    change_column :questionnaires, :scottish_personal_licence_qualification, 'boolean USING CAST(scottish_personal_licence_qualification AS boolean)'
    change_column :questionnaires, :dbs_qualification, 'boolean USING CAST(dbs_qualification AS boolean)'
    change_column :questionnaires, :food_health_level_two_qualification, 'boolean USING CAST(food_health_level_two_qualification AS boolean)'
    change_column :questionnaires, :english_personal_licence_qualification, 'boolean USING CAST(english_personal_licence_qualification AS boolean)'

    change_column :questionnaires, :week_days_work, 'boolean USING CAST(week_days_work AS boolean)'
    change_column :questionnaires, :weekends_work, 'boolean USING CAST(weekends_work AS boolean)'
    change_column :questionnaires, :day_shifts_work, 'boolean USING CAST(day_shifts_work AS boolean)'
    change_column :questionnaires, :evening_shifts_work, 'boolean USING CAST(evening_shifts_work AS boolean)'
  end

  def down
    change_column :questionnaires, :scottish_personal_licence_qualification, :string
    Questionnaire.where(scottish_personal_licence_qualification: 'false').update(scottish_personal_licence_qualification: '0')
    Questionnaire.where(scottish_personal_licence_qualification: 'true').update(scottish_personal_licence_qualification: '1')
    change_column :questionnaires, :dbs_qualification, :string
    Questionnaire.where(dbs_qualification: 'false').update(dbs_qualification: '0')
    Questionnaire.where(dbs_qualification: 'true').update(dbs_qualification: '1')
    change_column :questionnaires, :food_health_level_two_qualification, :string
    Questionnaire.where(food_health_level_two_qualification: 'false').update(food_health_level_two_qualification: '0')
    Questionnaire.where(food_health_level_two_qualification: 'true').update(food_health_level_two_qualification: '1')
    change_column :questionnaires, :english_personal_licence_qualification, :string
    Questionnaire.where(english_personal_licence_qualification: 'false').update(english_personal_licence_qualification: '0')
    Questionnaire.where(english_personal_licence_qualification: 'true').update(english_personal_licence_qualification: '1')

    change_column :questionnaires, :week_days_work, :string
    Questionnaire.where(week_days_work: 'false').update(week_days_work: '0')
    Questionnaire.where(week_days_work: 'true').update(week_days_work: '1')
    change_column :questionnaires, :weekends_work, :string
    Questionnaire.where(weekends_work: 'false').update(weekends_work: '0')
    Questionnaire.where(weekends_work: 'true').update(weekends_work: '1')
    change_column :questionnaires, :day_shifts_work, :string
    Questionnaire.where(day_shifts_work: 'false').update(day_shifts_work: '0')
    Questionnaire.where(day_shifts_work: 'true').update(day_shifts_work: '1')
    change_column :questionnaires, :evening_shifts_work, :string
    Questionnaire.where(evening_shifts_work: 'false').update(evening_shifts_work: '0')
    Questionnaire.where(evening_shifts_work: 'true').update(evening_shifts_work: '1')
  end
end
