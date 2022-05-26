require 'office_zone_sync'

class TimesheetEntry < ApplicationRecord
  include OfficeZoneSync

  belongs_to :tax_week
  belongs_to :pay_week, optional: true
  belongs_to :gig_assignment
  belongs_to :time_clock_report, optional: true

  delegate :gig, to: :gig_assignment
  delegate :assignment, to: :gig_assignment
  delegate :job, to: :assignment
  delegate :shift, to: :assignment
  delegate :date, to: :shift
  delegate :event, to: :gig
  delegate :prospect, to: :gig

  validates_presence_of :tax_week_id
  validates_presence_of :gig_assignment_id
  validates_presence_of :status
  validates :status,    inclusion: { in: %w{NEW PENDING SUBMITTED TO_APPROVE}}, allow_nil: false
  validates_inclusion_of :rating, :in => 1..5, allow_nil: true, message: 'must be from 1 to 5'

  after_save    :create_and_sync_pay_weeks
  after_destroy :sync_pay_weeks

  before_destroy do
    errors.add(:base, "Cannot Delete Submitted Timesheets") if status == 'SUBMITTED'
    throw(:abort) if errors.present?
  end

  after_update :update_gig_rating, if: -> { saved_change_to_attribute?(:rating) }

  def total_hours
    if time_start && time_end then
      datetime_start = DateTime.new(1970,1,1,time_start.hour, time_start.min, time_start.sec)
      datetime_end = DateTime.new(1970,1, (time_start < time_end ? 1 : 2), time_end.hour, time_end.min, time_end.sec)

      if event.paid_breaks?
        ((datetime_end - datetime_start) * 24.0).to_f.round(2)
      else
        ((((datetime_end - datetime_start) * 24.0 * 60.0 ) - (break_minutes || 0.0))/60.0).to_f.round(2)
      end
    else
      0
    end
  end

  def update_gig_rating
    timesheet_entries = gig.timesheet_entries
    ratings = timesheet_entries.pluck(:rating).compact
    gig.rating = ratings.length > 0 ? (ratings.inject(0) { |sum, n| sum + n}.to_f / ratings.size) : nil
    gig.save!
  end

  def create_and_sync_pay_weeks
    if pay_week
      sync_pay_weeks
    else
      pay_week
      pay_week = PayWeek.where(
        event_id:    event.id,
        tax_week_id: tax_week.id,
        job_id:      job.id,
        rate:        job.rate_for_person(prospect, tax_week.date_end),
        prospect_id: prospect.id,
        type: 'AUTO').first_or_initialize
      pay_week.status = status unless pay_week.status
      if pay_week.save
        self.update_attributes(pay_week_id: pay_week.id)
        sync_pay_weeks
      else
        errors.add(:base, "Error creating Auto Payroll Entry")
      end
    end
  end

  def sync_pay_weeks
    timesheet_entries = TimesheetEntry.where(pay_week_id: pay_week.id)
    if timesheet_entries.length > 0
      hours = {monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0}
      TimesheetEntry.includes(:gig_assignment).where(pay_week_id: pay_week.id).each do |timesheet_entry|
        day_of_week = timesheet_entry.date.strftime('%A').downcase.to_sym
        hours[day_of_week] += timesheet_entry.total_hours
      end
      hours.each { |day_of_week, h| pay_week[day_of_week] = h }
      unless pay_week.save
        errors.add(:base, "Error updating Auto Payroll Entry")
      end
    else
      pay_week.destroy
    end
  end

end