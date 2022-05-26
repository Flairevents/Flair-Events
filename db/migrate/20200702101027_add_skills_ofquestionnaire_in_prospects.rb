class AddSkillsOfquestionnaireInProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :bar_skill, :string
    add_column :prospects, :promo_skill, :string
    add_column :prospects, :sport_skill, :string
    add_column :prospects, :office_skill, :string
    add_column :prospects, :retail_skill, :string
    add_column :prospects, :festival_skill, :string

    bar_skill_questionnaires = Questionnaire.where.not(has_bar_and_hospitality: nil)
    Prospect.where(id: bar_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.bar_skill = prospect.questionnaire.has_bar_and_hospitality
      prospect.save
    end

    promo_skill_questionnaires = Questionnaire.where.not(has_promotional_and_street_marketing: nil)
    Prospect.where(id: promo_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.promo_skill = prospect.questionnaire.has_promotional_and_street_marketing
      prospect.save
    end

    sport_skill_questionnaires = Questionnaire.where.not(has_sport_and_outdoor: nil)
    Prospect.where(id: sport_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.sport_skill = prospect.questionnaire.has_sport_and_outdoor
      prospect.save
    end

    office_skill_questionnaires = Questionnaire.where.not(has_reception_and_office_admin: nil)
    Prospect.where(id: office_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.office_skill = prospect.questionnaire.has_reception_and_office_admin
      prospect.save
    end

    retail_skill_questionnaires = Questionnaire.where.not(has_merchandise_and_retail: nil)
    Prospect.where(id: retail_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.retail_skill = prospect.questionnaire.has_merchandise_and_retail
      prospect.save
    end

    festival_skill_questionnaires = Questionnaire.where.not(has_festivals_and_concerts: nil)
    Prospect.where(id: festival_skill_questionnaires.pluck(:prospect_id)).each do |prospect|
      prospect.festival_skill = prospect.questionnaire.has_festivals_and_concerts
      prospect.save
    end

  end
end
