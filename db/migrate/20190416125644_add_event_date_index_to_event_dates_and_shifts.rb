class AddEventDateIndexToEventDatesAndShifts < ActiveRecord::Migration[5.2]
  def change
    add_index :event_dates, [:event_id, :date]
    add_index :shifts, [:event_id, :date]
  end
end
