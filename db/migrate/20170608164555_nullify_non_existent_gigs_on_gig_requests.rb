class NullifyNonExistentGigsOnGigRequests < ActiveRecord::Migration[4.2]
  def change
    gig_requests_with_bad_gig_ids = GigRequest.all.select { |gr| gr.gig_id && Gig.find_by_id(gr.gig_id).nil? } 
    gig_requests_with_bad_gig_ids.each do |gr|
      gr.gig_id = nil
      gr.save
    end
  end
end
