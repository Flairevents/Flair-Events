class AddJobToGig < ActiveRecord::Migration[5.1]
  def change
    add_column :gigs, :job_id, :integer

    Gig.all.each do |gig|
      jobs = gig.gig_assignments.map { |ga| ga.job }.uniq
      if jobs.length == 1
        gig.job_id = jobs.first.id
        gig.save!
      end
    end
  end
end
