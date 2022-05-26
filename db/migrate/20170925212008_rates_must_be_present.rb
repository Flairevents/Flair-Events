class RatesMustBePresent < ActiveRecord::Migration[5.1]
  def change
    execute "UPDATE shifts SET pay_under_18 = 0 WHERE pay_under_18 IS NULL"
    execute "UPDATE shifts SET pay_25_and_over = 0 WHERE pay_25_and_over IS NULL"
    execute "ALTER TABLE shifts ADD CHECK (pay_under_18 >= 0)"
    execute "ALTER TABLE shifts ADD CHECK (pay_25_and_over >= 0)"
  end
end
