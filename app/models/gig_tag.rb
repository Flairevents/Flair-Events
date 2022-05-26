require 'office_zone_sync'

class GigTag < ApplicationRecord
  include OfficeZoneSync

  belongs_to :gig
  belongs_to :tag

  validates_presence_of :gig_id, :tag_id
  validates_uniqueness_of :gig_id, scope: :tag_id
end