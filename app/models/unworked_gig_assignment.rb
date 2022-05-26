require 'office_zone_sync'

class UnworkedGigAssignment < ApplicationRecord
  include OfficeZoneSync

  belongs_to :gig
  belongs_to :assignment

  validates_presence_of :gig_id, :assignment_id, :reason
  validates_uniqueness_of :assignment_id, scope: :gig_id

  REASONS = ["No Show", "Sent Home", "Cancelled"].freeze
  validates_inclusion_of :reason, in: REASONS
end