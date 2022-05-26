class RenameActiveColumnInProspects < ActiveRecord::Migration[5.1]
  def change
    rename_column :prospects, :active, :active_in_payroll
    rename_column :prospects, :date_inactive, :date_inactive_in_payroll
  end
end
