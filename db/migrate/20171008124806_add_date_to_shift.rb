class AddDateToShift < ActiveRecord::Migration[5.1]
  def change
    add_column :shifts, :date, :date
    execute "UPDATE shifts SET date = events.date_start FROM events WHERE events.id = shifts.event_id"
    execute "ALTER TABLE shifts ALTER COLUMN date SET NOT NULL"
  end
end
