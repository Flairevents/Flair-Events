require 'office_zone_sync'

class TimeClockReport < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  belongs_to :tax_week
  has_many :timesheet_entries, dependent: :restrict_with_error

  ALLOWED_USER_TYPES = %w[Prospect Officer ClientContact].freeze
  belongs_to :user, polymorphic: true
  validates :user_id, presence: true, numericality: { only_integer: true }
  validates :user_type, presence: true, inclusion: { in: ALLOWED_USER_TYPES }

  validates :status,    inclusion: { in: %w{SUBMITTED APPROVED}}, allow_nil: false
  validates_presence_of :event_id, :date

  before_validation do |time_clock_report|
    if time_clock_report.date && tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', time_clock_report.date, time_clock_report.date).first
      time_clock_report.tax_week_id = tax_week.id
    end
  end

  def signature_url
    signature ? "/event_date_signature/#{self.id}" : ""
  end
end