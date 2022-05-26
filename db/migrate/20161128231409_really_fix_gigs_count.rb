class ReallyFixGigsCount < ActiveRecord::Migration
  def change
    for fix in Gig.counter_culture_fix_counts
      if fix[:entity] == 'Event'
        e = Event.find(fix[:id])
        if e.additional_staff >= 0
          if e.additional_staff - fix[:right] >= 0
            additional_staff = e.additional_staff - fix[:right]
          else
            additional_staff = 0
          end
          puts "----------#{e.id}: #{e.name} : #{e.display_name}----------"
          puts "Number of Gigs: #{e.gigs_count}"
          puts "Updating Additional Staff: #{e.additional_staff} -> #{additional_staff}"
          e.additional_staff = additional_staff
          e.save
        end
      end
    end
  end
end
