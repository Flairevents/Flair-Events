class MigrateTaxYearAndWeekPrep < ActiveRecord::Migration[4.2]
  def change
    rename_column :pay_weeks, :tax_week, :tax_week2
    rename_column :pay_week_details_histories, :tax_week, :tax_week2
    rename_column :invoices, :tax_week, :tax_week2
    add_column :pay_weeks, :tax_week3_id, :integer
    add_column :pay_week_details_histories, :tax_week3_id, :integer
    add_column :invoices, :tax_week3_id, :integer
  end
end
