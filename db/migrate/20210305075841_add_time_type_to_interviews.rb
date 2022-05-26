class AddTimeTypeToInterviews < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :time_type, :string
  end
end
