class SetUniqueTaxWeekAndGigIndexOnGigTaxWeek < ActiveRecord::Migration[5.1]
  def change
    ##### Destroy accidentally created duplicate GigTaxWeek. We'll delete the oldest ones
    to_destroy = []
    GigTaxWeek.all.each do |gig_tax_week|
      gig_tax_weeks = GigTaxWeek.where(tax_week_id: gig_tax_week.tax_week_id, gig_id: gig_tax_week.gig_id)
      if gig_tax_weeks.length > 1
        to_destroy = to_destroy + gig_tax_weeks.sort_by(&:updated_at).take(gig_tax_weeks.length-1).pluck(:id)
      end
    end
    GigTaxWeek.where(id: to_destroy.uniq).destroy_all

    add_index :gig_tax_weeks, [:gig_id, :tax_week_id], unique: true
  end
end
