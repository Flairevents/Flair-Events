class AddNewShowInBooleansToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :show_in_home,     :boolean, default: true, null: false
    add_column :events, :show_in_payroll,  :boolean, default: true, null: false
  end
end
