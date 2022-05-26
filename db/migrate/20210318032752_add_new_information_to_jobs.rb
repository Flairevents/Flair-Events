class AddNewInformationToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :shift_information, :text
    add_column :jobs, :number_of_positions, :integer
  end
end
