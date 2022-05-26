require 'office_zone_sync'

class Expense < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event

  validates_presence_of :name, :event_id
end