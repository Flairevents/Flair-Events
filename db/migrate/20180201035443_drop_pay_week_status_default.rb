class DropPayWeekStatusDefault < ActiveRecord::Migration[5.1]
  def up
    db.execute "ALTER TABLE pay_weeks ALTER COLUMN status DROP DEFAULT"
  end

  def down
    db.execute "ALTER TABLE pay_weeks ALTER COLUMN status SET DEFAULT 'new'" #Note, the old value is wrong, should be uppercase
  end
end
