class RemoveStaffCountFromLocation < ActiveRecord::Migration[5.1]
  def change
    remove_column :locations, :staff_count, :integer
  end
end
