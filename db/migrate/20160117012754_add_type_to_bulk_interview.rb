class AddTypeToBulkInterview < ActiveRecord::Migration
  def up
    add_column :bulk_interviews, :interview_type, :string
  end
  def down
    remove_column :bulk_interviews, :interview_type
  end
end
