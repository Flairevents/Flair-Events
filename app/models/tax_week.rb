require 'office_zone_sync'

class TaxWeek < ApplicationRecord
  include OfficeZoneSync

  belongs_to    :tax_year
  has_many      :pay_week_details_histories, dependent: :restrict_with_error
  has_many      :pay_weeks, dependent: :restrict_with_error
  has_many      :timesheet_entries, dependent: :restrict_with_error
  has_many      :gig_tax_weeks, dependent: :restrict_with_error
  has_many      :payroll_activities, dependent: :restrict_with_error
  has_many      :shifts, dependent: :restrict_with_error
  has_many      :event_dates, dependent: :restrict_with_error
  has_many      :event_tasks, dependent: :restrict_with_error
  has_many      :time_clock_reports, dependent: :restrict_with_error

  validates_presence_of :tax_year_id, :week, :date_start, :date_end
end
