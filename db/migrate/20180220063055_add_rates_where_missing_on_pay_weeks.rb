class AddRatesWhereMissingOnPayWeeks < ActiveRecord::Migration[5.1]
  def change
    ##### This normally not needed. Just fixing a bug where auto payroll entries were being created without a rate
    PayWeek.where(rate: nil, type: 'AUTO').each do |pay_week|
      if job = pay_week.job
        pay_week.rate = job.rate_for_person(pay_week.prospect, pay_week.tax_week.date_end)
        pay_week.save!
      end
    end 
  end
end
