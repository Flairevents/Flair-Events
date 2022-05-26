module SharedEventMethods
  def self.get_job_groups(events)
    job_groups = {}
    events.each do |event|
      job_groups[event.id] = {}
      event.jobs.select {|job| job.include_in_description}.group_by { |job| "#{job.pay_18_and_over}|#{job.pay_21_and_over}|#{job.pay_25_and_over}" }.each do |pay_key, jobs|
        job_groups[event.id][pay_key] ||= {}
        job_groups[event.id][pay_key][:names] = jobs.map { |job| job.pretty_name}
        job_groups[event.id][pay_key][:pay_rates] ||= []
        job = jobs.first # Rates are all the same for this set of jobs since we grouped them by rates
        case
          when job.pay_18_and_over == job.pay_21_and_over && job.pay_21_and_over == job.pay_25_and_over
            job_groups[event.id][pay_key][:pay_rates] << {age: '', pay: job.pay_18_and_over, base_pay: job.base_pay(:pay_18_and_over), holiday_pay: job.holiday_pay(:pay_18_and_over)}
          when job.pay_18_and_over == job.pay_21_and_over
            job_groups[event.id][pay_key][:pay_rates] << {age: '25+',   pay: job.pay_25_and_over, base_pay: job.base_pay(:pay_25_and_over), holiday_pay: job.holiday_pay(:pay_25_and_over)}
            job_groups[event.id][pay_key][:pay_rates] << {age: '18-24', pay: job.pay_21_and_over, base_pay: job.base_pay(:pay_21_and_over), holiday_pay: job.holiday_pay(:pay_21_and_over)}
          when job.pay_21_and_over == job.pay_25_and_over
            job_groups[event.id][pay_key][:pay_rates] << {age: '21+',   pay: job.pay_25_and_over, base_pay: job.base_pay(:pay_25_and_over), holiday_pay: job.holiday_pay(:pay_25_and_over)}
            job_groups[event.id][pay_key][:pay_rates] << {age: '18-20', pay: job.pay_18_and_over, base_pay: job.base_pay(:pay_18_and_over), holiday_pay: job.holiday_pay(:pay_18_and_over)}
          else
            job_groups[event.id][pay_key][:pay_rates] << {age: '25+',   pay: job.pay_25_and_over, base_pay: job.base_pay(:pay_25_and_over), holiday_pay: job.holiday_pay(:pay_25_and_over)}
            job_groups[event.id][pay_key][:pay_rates] << {age: '21-24', pay: job.pay_21_and_over, base_pay: job.base_pay(:pay_21_and_over), holiday_pay: job.holiday_pay(:pay_21_and_over)}
            job_groups[event.id][pay_key][:pay_rates] << {age: '18-20', pay: job.pay_18_and_over, base_pay: job.base_pay(:pay_18_and_over), holiday_pay: job.holiday_pay(:pay_18_and_over)}
        end
      end
    end
    job_groups
  end
end
