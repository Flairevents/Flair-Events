require 'office_zone_sync'

class EventDate < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  belongs_to :tax_week

  validates_presence_of :event, :tax_week, :date
  validates :date, uniqueness: {scope: :event_id}
  validate :validate_date_in_range

  after_commit :update_next_active_date_on_event
  def update_next_active_date_on_event
    Event.find_by_id(self.event_id).try(:update_next_active_date_on_event)
  end

  before_validation do |event_date|
    if event_date.date && (tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', event_date.date, event_date.date).first)
      event_date.tax_week_id = tax_week.id
    end
  end

  def validate_date_in_range
    errors.add(:date, "must be within event start and end") if date < event.date_start or date > event.date_end
  end
end