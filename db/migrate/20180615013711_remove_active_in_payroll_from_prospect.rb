class RemoveActiveInPayrollFromProspect < ActiveRecord::Migration[5.1]
  def change
    remove_column :prospects, :active_in_payroll, :boolean
    remove_column :prospects, :date_inactive_in_payroll, :boolean
  end
end
