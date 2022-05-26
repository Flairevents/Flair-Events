class AddDbsQualificationTypeToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :dbs_qualification_type, :string

    Prospect.joins(:questionnaire).where(questionnaires: { dbs_qualification: true }).update_all(dbs_qualification_type: 'Basic')
  end
end
