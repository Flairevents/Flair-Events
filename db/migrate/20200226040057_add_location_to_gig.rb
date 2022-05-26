class AddLocationToGig < ActiveRecord::Migration[5.2]
  def up
    add_column :gigs, :location_id, :integer, null: true, default: nil

    Gig.all.each do |gig|
      locations = gig.gig_assignments.map { |ga| ga.location }.uniq
      if locations.length == 1
        gig.location_id = locations.first.id
        gig.save!
      end
    end  
  end
end
