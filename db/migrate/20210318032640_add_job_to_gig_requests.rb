class AddJobToGigRequests < ActiveRecord::Migration[5.2]
  def change
    add_reference :gig_requests, :job, foreign_key: true
  end
end
