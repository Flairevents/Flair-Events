class FixGigsCount < ActiveRecord::Migration
  def change
    Event.all.each do |e|
      gigs_count = Gig.where(event_id: e.id).length
      if e.gigs_count != gigs_count
        puts "***** #{e.name} *****"
        puts "Updating Gigs Count:       #{e.gigs_count} -> #{gigs_count}"
        if e.additional_staff - gigs_count >= 0
          puts "Updating Additional Staff: #{e.additional_staff} -> #{e.additional_staff - gigs_count}"
          e.additional_staff = e.additional_staff - gigs_count
        end 
        e.gigs_count = gigs_count
        e.save
      end
    end
  end
end
