class ClearJobOnPayweekIfRateDoesntMatch < ActiveRecord::Migration[5.1]
  def up
    PayWeek.all.each do |pay_week|
      if pay_week.job_id
        job_rate = pay_week.job.rate_for_person(pay_week.prospect, pay_week.tax_week.date_end)
        unless job_rate == pay_week.rate
          pay_week.job_id = nil
          pay_week.save!
        end
      end
    end
  end
end
