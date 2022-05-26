class AddStatusToBulkInterview < ActiveRecord::Migration
  def up
    add_column :bulk_interviews, :status, :string, default: 'NEW'
  end
  def down
    remove_column :bulk_interviews, :status
  end
end
