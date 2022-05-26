class AddFirstAndLastNameColumnsToPayrollReports < ActiveRecord::Migration
  def up
    Report.where(name: 'payroll_summary', table: 'tax_weeks').destroy_all
    Report.create!(name: 'payroll_summary', print_name: 'Tax Week Details', table: 'tax_weeks',
                   fields: ['name', 'first_name', 'last_name', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'rate', 'total_pay', 'event', 'allowance', 'deduction', 'job', 'location', 'shift'],
                   row_numbers: true)
    Report.where(name: 'wage_details', table: 'tax_weeks').destroy_all
    Report.create!(name: 'wage_details', print_name: 'Wage Details', table: 'tax_weeks',
                   fields: ['name', 'first_name', 'last_name', 'bank_sort_code', 'bank_account_no', 'payment_method'],
                   row_numbers: true)
  end
  def down
    Report.create!(name: 'payroll_summary', print_name: 'Wage Details', table: 'tax_weeks',
                   fields: ['name', 'bank_sort_code', 'bank_account_no', 'payment_method'],
                   row_numbers: true)
    Report.create!(name: 'payroll_summary', print_name: 'Tax Week Details', table: 'tax_weeks',
                   fields: ['name', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'rate', 'total_pay', 'event', 'allowance', 'deduction', 'job', 'location', 'shift'],
                   row_numbers: true)
    Report.where(name: 'wage_details', table: 'tax_weeks').destroy_all
    Report.create!(name: 'wage_details', print_name: 'Wage Details', table: 'tax_weeks',
                   fields: ['name', 'bank_sort_code', 'bank_account_no', 'payment_method'],
                   row_numbers: true)
  end
end
