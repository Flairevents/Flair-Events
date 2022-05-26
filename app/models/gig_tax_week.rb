require 'office_zone_sync'

class GigTaxWeek < ApplicationRecord
  include OfficeZoneSync

  belongs_to :gig
  belongs_to :tax_week
  belongs_to :assignment_email_template, optional: true

  validates_presence_of :gig_id, :tax_week_id
  validates_uniqueness_of :gig_id, scope: :tax_week_id
  validates_inclusion_of :assignment_email_type, in: %w(Info Reserve ShiftOffer CallToConfirm EmailToConfirm Booked BookedOffer Final Change), allow_nil: true

  after_update :update_assignment_counts
  after_update :update_gig_published_attribute

  def update_assignment_counts
    if self.saved_change_to_confirmed?
      self.gig.gig_assignments.includes(assignment: [:shift]).each do |ga|
        ga.assignment.update_staff_counts if ga.assignment.shift.tax_week_id == self.tax_week_id
      end
    end
  end

  # For the webapp_data export
  def update_gig_published_attribute
    if self.saved_change_to_confirmed?
      self.gig.update published: false
    end
  end

end
