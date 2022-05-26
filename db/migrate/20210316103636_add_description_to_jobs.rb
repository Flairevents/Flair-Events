class AddDescriptionToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :new_description, :text
  end
end
