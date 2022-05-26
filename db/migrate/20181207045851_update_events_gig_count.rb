class UpdateEventsGigCount < ActiveRecord::Migration[5.2]
  def change
    Event.all.each {|event| event.update_gigs_count }
  end
end
