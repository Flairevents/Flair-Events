class RemoveTypeFromJobs < ActiveRecord::Migration[5.2]
  def change
    remove_column :jobs, :type, :string, null: false, default: 'REGULAR'
  end
end
