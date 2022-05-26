class AddStaffNeededToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :staff_needed, :integer
  end
end
