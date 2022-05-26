class ChangeAdditionalStaffDefaultToZero < ActiveRecord::Migration
  def change
    change_column :events, :additional_staff, :integer, default: 0, null: false
  end
end
