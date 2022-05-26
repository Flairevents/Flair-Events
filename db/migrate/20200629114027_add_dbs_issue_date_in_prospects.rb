class AddDbsIssueDateInProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :dbs_issue_date, :date
  end
end
