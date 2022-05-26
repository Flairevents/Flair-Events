class AddNewEmployeeToProspect < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :new_employee, :boolean, default: false
  end
end
