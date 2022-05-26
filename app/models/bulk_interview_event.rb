require 'office_zone_sync'

class BulkInterviewEvent < ApplicationRecord
  include OfficeZoneSync

  belongs_to :bulk_interview
  belongs_to :event

  validates_presence_of :bulk_interview_id, :event_id
end