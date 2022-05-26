class UpdateTaxWeeksPart1 < ActiveRecord::Migration
  def up
    ##### We don't have constraints yet because we don't want previously created tax weeks to fail
    ##### After manually running a porting command to copy over the right values to gig_id and shift_id,
    ##### Then we can add constraints and drop the old columns (UpdateTaxWeekModel_PostManualAttributeFix)
    add_column :tax_weeks, :gig_id, :integer
    add_column :tax_weeks, :shift_id, :integer
  end

  def down
    remove_column :tax_weeks, :gig_id
    remove_column :tax_weeks, :shift_id
  end
end

##### Run the following code in a console (uncomment it!) after migrating part 1. After code is run, migrate with part 2:
#
#TaxWeek.all.each do |tw|
#  unless tw.gig_id
#    gigs = Gig.where(event_id: tw.event_id, prospect_id: tw.prospect_id)
#    raise "Oh, Oh. There is more than one gig for event #{tw.event_id} & prospect ${tw.prospect_id}" if gigs.length > 1 
#    tw.gig_id = gigs[0].id
#  end
#  unless tw.shift_id
#    unless tw.shift == 'X'
#      job_id = Job.where(event_id: tw.event_id, name: tw.job_role)
#      shifts = Shift.where(job_id: job_id, name: tw.shift)
#      raise "Oh, Oh. There is more than one shift for job #{job_id} & shift #{tw.shift}" if gigs.length > 1 
#      tw.shift_id = shifts[0].id
#    end
#  end
#  tw.save!
#end
