class AdjustStatusCheckOnEvents < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE events DROP CONSTRAINT events_status_check"
    db.execute "ALTER TABLE events ADD CHECK (status IN ('NEW', 'OPEN', 'CANCELLED', 'FULL', 'HIDDEN', 'HAPPENING', 'FINISHED', 'CLOSED'))"
  end

  def down
    db.execute "ALTER TABLE events DROP CONSTRAINT events_status_check"
    db.execute "ALTER TABLE events ADD CHECK (status IN ('NEW', 'OPEN', 'CANCELLED', 'FULL', 'HIDDEN', 'HAPPENING', 'CLOSED'))"
  end
end
