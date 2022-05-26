class ChangedManagerStaffValuesOfSkillsAndMarketing < ActiveRecord::Migration[5.2]
  def change
    top_medium_volume_prospects = Prospect.where(manager_level: ['Level 1', 'Level 2'])
    top_medium_volume_prospects.update_all(has_bar_management_experience: true, has_staff_leadership_experience: true)
    Questionnaire.where(prospect_id: top_medium_volume_prospects.pluck(:id)).update_all(bar_management_experience: true, staff_leadership_experience: true)

    flair_tl_prospects = Prospect.where(manager_level: 'Level 3')
    flair_tl_prospects.update_all(has_staff_leadership_experience: true)
    Questionnaire.where(prospect_id: flair_tl_prospects.pluck(:id)).update_all(staff_leadership_experience: true)
  end
end
