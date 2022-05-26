class AddExperiencesColumnsInProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :has_sport_and_outdoor, :boolean, default: false, null: false
    add_column :prospects, :has_bar_and_hospitality, :boolean, default: false, null: false
    add_column :prospects, :has_festivals_and_concerts, :boolean, default: false, null: false
    add_column :prospects, :has_merchandise_and_retail, :boolean, default: false, null: false
    add_column :prospects, :has_promotional_and_street_marketing, :boolean, default: false, null: false
    add_column :prospects, :has_reception_and_office_admin, :boolean, default: false, null: false

    prospect_ids = Questionnaire.where.not(has_sport_and_outdoor: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_sport_and_outdoor: true )

    prospect_ids = Questionnaire.where.not(has_bar_and_hospitality: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_bar_and_hospitality: true )

    prospect_ids = Questionnaire.where.not(has_festivals_and_concerts: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_festivals_and_concerts: true )

    prospect_ids = Questionnaire.where.not(has_merchandise_and_retail: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_merchandise_and_retail: true )

    prospect_ids = Questionnaire.where.not(has_promotional_and_street_marketing: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_promotional_and_street_marketing: true )

    prospect_ids = Questionnaire.where.not(has_reception_and_office_admin: nil).pluck(:prospect_id)
    Prospect.where(id: prospect_ids).update(has_reception_and_office_admin: true )

    add_column :prospects, :has_bar_management_experience, :boolean, default: false, null: false
    add_column :prospects, :has_staff_leadership_experience, :boolean, default: false, null: false

    Prospect.where(id: Questionnaire.where.not(bar_management_experience: nil).pluck(:prospect_id)).update_all(has_bar_management_experience: true )
    Prospect.where(id: Questionnaire.where.not(staff_leadership_experience: nil).pluck(:prospect_id)).update_all(has_staff_leadership_experience: true )
  end
end
