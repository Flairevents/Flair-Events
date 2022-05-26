class ChangedTheValuesOfMarketingForFourOrAboveRating < ActiveRecord::Migration[5.2]
  def change
    Prospect.where(status: 'EMPLOYEE').each do |prospect|
      all_gigs_with_rating = Gig.where(prospect_id: prospect.id).where.not(rating: nil)
      average_rating = all_gigs_with_rating.length > 0 ? all_gigs_with_rating.average(:rating).round(2) : (prospect.rating? ? prospect.rating.round(2) : 0)
      if average_rating >= 4
        prospect.has_bar_and_hospitality = true
        prospect.has_hospitality_marketing = true
        prospect.has_sport_and_outdoor = true
        prospect.has_promotional_and_street_marketing = true
        prospect.has_merchandise_and_retail = true
        prospect.has_reception_and_office_admin = true
        prospect.has_festivals_and_concerts = true
        prospect.has_warehouse_marketing = true
        prospect.save
      end
    end

  end
end
