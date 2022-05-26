class AddOtherInfoToJobs < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:jobs, :other_information)
      add_column :jobs, :other_information, :text
    end
  end
end
