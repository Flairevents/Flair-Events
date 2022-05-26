class MoveGigCallbackToGigTaxWeekConfirmed < ActiveRecord::Migration[5.1]
  def change
    add_column :gig_tax_weeks, :confirmed, :boolean, null: false, default: false 

    ##### Create Gig Tax Weeks where needed to store callback
    ##### We don't create GigTaxWeeks for everything as we only create them when needed.
    ##### This makes it easier to manage events that have their dates changed around,
    ##### which would require a mess of logic to move/delete/add gig_tax_weeks
    Gig.where(callback: true).each do |gig|
      TaxWeek.where('date_start <= ?  AND ? <= date_end', gig.event.date_end, gig.event.date_start).each do |tax_week|
        gig_tax_week = GigTaxWeek.where(gig_id: gig.id, tax_week_id: tax_week.id).first_or_create
        gig_tax_week.confirmed = gig.callback
        gig_tax_week.save
      end
    end

    remove_column :gigs, :callback
  end
end
