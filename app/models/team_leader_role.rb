require 'office_zone_sync'

class TeamLeaderRole < ApplicationRecord
  include OfficeZoneSync
  ALLOWED_USER_TYPES = %w[Prospect Officer ClientContact].freeze
  belongs_to :user, polymorphic: true
  belongs_to :event

  validates :user_id, presence: true, numericality: { only_integer: true }
  validates :user_type, presence: true, inclusion: { in: ALLOWED_USER_TYPES }
  validates :user_id, uniqueness: { scope: [:event_id, :user_type] }
  validates :event_id, presence: true
end
