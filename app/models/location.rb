require 'office_zone_sync'

class Location < ApplicationRecord
  include OfficeZoneSync

  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'

  belongs_to :event
  has_many   :gigs,          dependent: :restrict_with_error
  has_many   :assignments,   dependent: :restrict_with_error

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:event_id, :type]

  TYPES = %w{REGULAR FLOATER SPARE}.freeze
  validates_inclusion_of :type, in: TYPES

  def to_print
    type != 'REGULAR' && !(/SPARE|FLOATER/i.match(name)) ? "#{name} (#{type.titleize})" : name
  end

  before_destroy do |location|
    event = location.event
    if event.default_location_id == location.id
      event.default_location_id = nil
      throw :abort unless event.save
    end
  end
end
