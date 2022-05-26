class EventDisplayNameIsMandatory < ActiveRecord::Migration[5.2]
  def change
    db.execute "UPDATE events SET display_name = name WHERE display_name IS NULL OR display_name = ''"
    db.execute "ALTER TABLE events ALTER COLUMN display_name SET NOT NULL"
    db.execute "ALTER TABLE events ADD CHECK (display_name <> '')"
  end
end
