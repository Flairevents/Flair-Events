class RenameTaxWeekToPayWeek < ActiveRecord::Migration[4.2]
  def change
    rename_table :tax_weeks, :pay_weeks
    rename_table :tax_week_details_histories, :pay_week_details_histories
  end
end
