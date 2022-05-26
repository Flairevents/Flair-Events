class AddTypeToJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :type, :string, null: false, default: 'REGULAR'
  end
end
