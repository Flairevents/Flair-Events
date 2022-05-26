class AddRegionToEventAndProspectAndBulkInterview < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :region
    add_reference :prospects, :region
    add_reference :bulk_interviews, :region
    Prospect.all.each do |prospect|
      prospect.region_id = prospect.region_id_from_post_code
      prospect.save
    end
    BulkInterview.all.each do |bulk_interview|
      bulk_interview.region_id = bulk_interview.region_id_from_post_code
      bulk_interview.save
    end
  end
end
