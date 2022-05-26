class LinkShiftsToEvent < ActiveRecord::Migration[5.1]
  def change
    # Shifts will also link to Events
    add_column :shifts, :event_id, :integer
    execute "UPDATE shifts SET event_id = jobs.event_id FROM jobs WHERE jobs.id = shifts.job_id"
    execute "ALTER TABLE shifts ALTER event_id SET NOT NULL"
    execute "ALTER TABLE shifts ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"
  end
end
