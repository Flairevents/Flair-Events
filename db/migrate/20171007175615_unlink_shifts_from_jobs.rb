class UnlinkShiftsFromJobs < ActiveRecord::Migration[5.1]
  def change
    # We won't be able to show Shift in the Gig Report any more
    Report.where(table: 'gigs').each do |r|
      if r.fields.include?('shift')
        r.fields.delete('shift')
        r.save!
      end
    end

    remove_column :shifts, :job_id
  end
end
