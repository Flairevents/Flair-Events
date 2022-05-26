class MigrateTaxYearAndWeekCleanup < ActiveRecord::Migration[4.2]
  def change
    remove_column :pay_weeks, :tax_year
    remove_column :pay_weeks, :tax_week2
    remove_column :pay_week_details_histories, :tax_year
    remove_column :pay_week_details_histories, :tax_week2
    remove_column :invoices, :tax_year
    remove_column :invoices, :tax_week2
    rename_column :pay_weeks, :tax_week3_id, :tax_week_id
    rename_column :pay_week_details_histories, :tax_week3_id, :tax_week_id
    rename_column :invoices, :tax_week3_id, :tax_week_id
    change_column_null :pay_weeks, :tax_week_id, false
    change_column_null :pay_week_details_histories, :tax_week_id, false
    change_column_null :invoices, :tax_week_id, false
  end
end
