class RegenerateGigRatings < ActiveRecord::Migration[5.1]
  def change
    TimesheetEntry.all.each {|tse| tse.update_gig_rating}
  end
end
