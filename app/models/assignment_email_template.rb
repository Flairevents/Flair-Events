require 'office_zone_sync'

class AssignmentEmailTemplate < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  has_many :gig_tax_weeks, dependent: :restrict_with_error

  validates_presence_of :event_id, :name
  validates_uniqueness_of :name, scope: [:event_id], message: "A template with that name already exists"
  validate :meeting_location_coords

  def validate_meeting_location_coords
    if meeting_location_coords
      coords = meeting_location_coords.split(',')
      unless coords.length == 2 and coords[0].is_numeric? and coords[1].is_numeric?
        errors.add(:base, "Meeting Location Coords are not valid coordinates")
      end
    end
  end

  def meeting_location_map_link
    if meeting_location_coords.present?
      coords = meeting_location_coords.split(',')
      "https://maps.google.com/maps?q=#{coords[0].to_f},#{coords[1].to_f}"
    else
      nil
    end
  end
end