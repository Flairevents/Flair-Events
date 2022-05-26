class AddDefaultValueToIsOngoingOnEvents < ActiveRecord::Migration
  def change
    db.execute "ALTER TABLE events ALTER COLUMN is_ongoing SET DEFAULT false"
  end
end
