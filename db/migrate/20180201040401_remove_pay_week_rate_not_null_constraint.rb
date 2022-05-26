class RemovePayWeekRateNotNullConstraint < ActiveRecord::Migration[5.1]
  def change
    change_column_null :pay_weeks, :rate, true
  end
end
