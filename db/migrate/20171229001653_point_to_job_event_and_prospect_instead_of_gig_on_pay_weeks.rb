class PointToJobEventAndProspectInsteadOfGigOnPayWeeks < ActiveRecord::Migration[5.1]
  def up
    add_column :pay_weeks, :job_id, :integer
    add_column :pay_weeks, :prospect_id, :integer
    add_column :pay_weeks, :event_id, :integer
    PayWeek.reset_column_information
    PayWeek.all.each do |pw|
      gig = Gig.find_by_id(pw.gig_id)
      if job = Job.find_by_id(gig.job_id)
        pw.job_id = job.id
      end
      prospect = Prospect.find_by_id(gig.prospect_id)
      event = Event.find_by_id(gig.event_id)
      pw.prospect_id = prospect.id
      pw.event_id = event.id
      pw.save!
    end
    remove_column :pay_weeks, :gig_id
    change_column_null :pay_weeks, :prospect_id, false
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
