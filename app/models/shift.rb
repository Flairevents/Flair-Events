require 'office_zone_sync'

class Shift < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  belongs_to :tax_week
  has_many   :assignments,   dependent: :restrict_with_error

  validates_presence_of :event_id, :date, :tax_week_id, :time_start, :time_end
  validate :validate_date

  before_validation do |shift|
    if shift.date && (tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', shift.date, shift.date).first)
      shift.tax_week_id = tax_week.id
    end
  end

  def validate_date
    errors.add(:date, "must be on a day on the event calendar") if EventDate.where(event: event, date: date).none?
  end

  def datetime_start
    DateTime.new(date.year, date.month, date.day, time_start.hour, time_start.min, time_start.sec)
  end

  def datetime_end
    datetime = DateTime.new(date.year, date.month, date.day, time_end.hour, time_end.min, time_end.sec)
    datetime += 1.day if time_end < time_start
    datetime
  end

  def to_print_time_span
    "#{time_start.strftime("%H:%M")}-#{time_end.strftime("%H:%M")}"
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({ :methods => [:datetime_start, :datetime_end] }))
  end
end
