class AddManagerAndStaffLeaderIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :bar_manager_skill, :boolean, default: false, null: false
    add_column :prospects, :staff_leader_skill, :boolean, default: false, null: false

    bar_manager_prospects = Prospect.where(id: Questionnaire.where(bar_management_experience: true).pluck(:prospect_id)).update_all(bar_manager_skill: true)
    staff_leader_prospects = Prospect.where(id: Questionnaire.where(staff_leadership_experience: true).pluck(:prospect_id)).update_all(staff_leader_skill: true)

  end
end
