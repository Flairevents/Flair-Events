class InitializeGigsCountAndAdditionalStaffInEvent < ActiveRecord::Migration
  def change
    Event.all.each do |e|
      e.gigs_count = Gig.where(event_id: e.id).length 
      if e.additional_staff && e.additional_staff >= e.gigs_count 
        e.additional_staff = e.additional_staff - e.gigs_count
      else
        e.additional_staff = 0
      end
      e.save
    end
  end
end
