class NoBreakMins < ActiveRecord::Migration[5.1]
  def change
    # This column is not needed any more
    remove_column :shifts, :break_mins
  end
end
