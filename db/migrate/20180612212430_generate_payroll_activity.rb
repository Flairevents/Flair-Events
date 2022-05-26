class GeneratePayrollActivity < ActiveRecord::Migration[5.1]
  def up
    PayWeekDetailsHistory.connection.schema_cache.clear!
    PayWeekDetailsHistory.reset_column_information
    oc = OfficeController.new
    tax_year = TaxYear.where("date_start <= ? AND ? <= date_end", Date.today, Date.today).first
    tax_weeks = TaxWeek.where("tax_year_id = ? AND date_end < ?", tax_year.id, Date.today).sort_by(&:date_start)
    tax_weeks.each do |tax_week|
      puts("Updating #{tax_week.inspect}")
      oc.update_payroll_activity_and_history(PayWeek.where(tax_week_id: tax_week.id))
    end
  end
  def down
    PayrollActivity.destroy_all
  end  
end