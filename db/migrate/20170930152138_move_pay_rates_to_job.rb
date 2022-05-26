class MovePayRatesToJob < ActiveRecord::Migration[5.1]
  def change
    # For a start, Pay Weeks don't need to link to Shifts
    remove_column :pay_weeks, :shift_id
    # The *only* thing affected by that is that we can't show the Shift in the PayWeeks
    #   report... well, we could still do so via a join, but it will add duplicate rows
    #   to the report...
    Report.where(table: 'pay_weeks').each do |r|
      if r.fields.include?('shift')
        r.fields.delete('shift')
        r.save!
      end
    end

    # Move payment details to Jobs, not Shifts
    add_column :jobs, :pay_18_and_over,    :decimal
    add_column :jobs, :pay_21_and_over,     :decimal
    add_column :jobs, :pay_17_and_under,    :decimal
    add_column :jobs, :pay_25_and_over, :decimal

    # Make Job names unique within each Event
    # (although we have an ActiveRecord validation for this, there are some non-unique
    #   records in the database)
    Job.joins("JOIN jobs j2 ON jobs.id > j2.id AND jobs.event_id = j2.event_id AND jobs.name = j2.name").each do |job|
      job.name += '2'
      # To save the record, we need to temporarily put something in the new columns
      # (to avoid failing an ActiveRecord validation)
      job.pay_17_and_under = job.pay_18_and_over = job.pay_21_and_over = job.pay_25_and_over = 0
      job.save!
    end

    Job.all.each do |job|
      shifts = Shift.where(job_id: job.id).order('time_start ASC')
      if shifts.empty?
        job.pay_18_and_over  = 0
        job.pay_21_and_over  = 0
        job.pay_17_and_under = 0
        job.pay_25_and_over  = 0
      else
        job.pay_18_and_over = shifts[0].pay_under_21
        job.pay_21_and_over = shifts[0].pay_over_21
        job.pay_17_and_under = shifts[0].pay_under_18
        job.pay_25_and_over = shifts[0].pay_25_and_over
      end
      job.save!
    end

    remove_column :shifts, :pay_under_21
    remove_column :shifts, :pay_over_21
    remove_column :shifts, :pay_under_18
    remove_column :shifts, :pay_25_and_over

    # Add constraints on pay rate columns in 'jobs'
    execute "ALTER TABLE jobs ALTER pay_17_and_under SET NOT NULL"
    execute "ALTER TABLE jobs ALTER pay_18_and_over SET NOT NULL"
    execute "ALTER TABLE jobs ALTER pay_21_and_over SET NOT NULL"
    execute "ALTER TABLE jobs ALTER pay_25_and_over SET NOT NULL"
    execute "ALTER TABLE jobs ADD CHECK (pay_17_and_under >= 0)"
    execute "ALTER TABLE jobs ADD CHECK (pay_18_and_over >= 0)"
    execute "ALTER TABLE jobs ADD CHECK (pay_21_and_over >= 0)"
    execute "ALTER TABLE jobs ADD CHECK (pay_25_and_over >= 0)"
  end
end
