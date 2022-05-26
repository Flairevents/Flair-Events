class RenamePartAndFullAssignmentEmailTypesOnGigTaxWeek < ActiveRecord::Migration[5.2]
  def change
    #hmmmm... we have some old gig_tax_weeks that point to deleted gigs. Must have
    # been from before we added the correct model assocations. Fix these first
    GigTaxWeek.all.each do |gtw|
      gtw.destroy if !gtw.gig
    end

    reversible do |change| 
      type_change = {}
      change.up   { type_change = {'Full': 'Final', 'Part': 'Booked'} }
      change.down { type_change = {'Final': 'Full', 'Booked': 'Part'} } 
      GigTaxWeek.where(assignment_email_type: type_change.keys).each do |gig_tax_week|
        gig_tax_week.assignment_email_type = type_change[gig_tax_week.assignment_email_type.to_sym]  
        gig_tax_week.save!
      end
    end
  end
end
