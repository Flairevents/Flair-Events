class AddTaxWeekReports < ActiveRecord::Migration
  def up
    Report.create!(name: 'gig_payroll', print_name: 'Gig Payroll', table: 'tax_weeks',
                   fields: ['name', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'allowance', 'deduction', 'total_pay', 'job', 'location', 'shift'],
                   row_numbers: true)
    Report.create!(name: 'week_payroll', print_name: 'Week Payroll', table: 'tax_weeks',
                   fields: ['name', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'rate', 'total_pay', 'event', 'allowance', 'deduction', 'job', 'location', 'shift'],
                   row_numbers: true)
    Report.create!(name: 'wage_details', print_name: 'Wage Details', table: 'tax_weeks',
                   fields: ['name', 'bank_sort_code', 'bank_account_no', 'payment_method'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'gig_payroll', table: 'tax_weeks').destroy_all
    Report.where(name: 'week_payroll', table: 'tax_weeks').destroy_all
    Report.where(name: 'wage_details', table: 'tax_weeks').destroy_all
  end
end
