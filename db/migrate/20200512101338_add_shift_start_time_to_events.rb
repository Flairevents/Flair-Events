class AddShiftStartTimeToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :shift_start_time, :text
  end
end
