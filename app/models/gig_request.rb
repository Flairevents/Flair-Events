require 'office_zone_sync'

class GigRequest < ApplicationRecord
  include OfficeZoneSync

  belongs_to :prospect
  belongs_to :event
  belongs_to :gig, optional: true
  belongs_to :job

  validates_uniqueness_of :prospect_id, scope: :event_id
  validate do |request|
    if request.gig_id.present? && request.spare
      request.errors.add(:base, 'Spare Gig Requests cannot be hired')
    end
  end

  def hired?
    !gig_id.nil?
  end
end
