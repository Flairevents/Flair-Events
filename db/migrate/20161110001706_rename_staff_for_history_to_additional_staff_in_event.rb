class RenameStaffForHistoryToAdditionalStaffInEvent < ActiveRecord::Migration
  def change
    rename_column :events, :staff_for_history, :additional_staff
  end
end
