require 'office_zone_sync'

class EventClient < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  belongs_to :client
  has_one :booking, dependent: :destroy
  has_many :invoices, dependent: :restrict_with_error

  validates_presence_of :event_id, :client_id
end