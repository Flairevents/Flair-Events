class AddExtraIdColumnsOnProspect < ActiveRecord::Migration[5.1]
  def change
    add_column :prospects, :visa_issue_date, :date
    add_column :prospects, :visa_indefinite, :boolean, null: false, default: false
  end
end
