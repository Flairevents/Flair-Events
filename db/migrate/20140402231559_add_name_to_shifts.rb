class AddNameToShifts < ActiveRecord::Migration
  def change
    db.execute "ALTER TABLE shifts ADD COLUMN name varchar(1) NOT NULL DEFAULT 'A'"
  end
end
