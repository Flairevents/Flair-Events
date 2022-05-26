require 'office_zone_sync'

class Tag < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  has_many   :gig_tags, dependent: :restrict_with_error

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :event_id
end