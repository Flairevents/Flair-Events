class AddUniformInformationToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :uniform_information, :text
  end
end
