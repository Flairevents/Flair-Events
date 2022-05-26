class UpdatePayrollReports < ActiveRecord::Migration[5.1]
  def up
    Report.find_by_name('payroll_summary').update(print_name: 'Pay Week Details', table: 'pay_weeks')
    Report.find_by_name('wage_details').update(table: 'pay_weeks')
  end
  def down
    Report.find_by_name('payroll_summary').update(print_name: 'Tax Week Details', table: 'tax_weeks')
    Report.find_by_name('wage_details').update(table: 'tax_weeks')
  end
end
