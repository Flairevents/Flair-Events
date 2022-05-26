require 'office_zone_sync'

class FaqEntry < ApplicationRecord
  include OfficeZoneSync

  validates_presence_of :question, :answer, :topic, :position
end