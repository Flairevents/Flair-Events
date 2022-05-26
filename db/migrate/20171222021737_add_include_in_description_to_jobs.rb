class AddIncludeInDescriptionToJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :include_in_description, :boolean, null: false, default: true
  end
end
