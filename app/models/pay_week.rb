require 'office_zone_sync'
require 'brightpay'
include Brightpay

class PayWeek < ApplicationRecord
  include OfficeZoneSync

  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'

  belongs_to :tax_week
  belongs_to :job, optional: true
  belongs_to :prospect
  belongs_to :event, optional: true
  has_many :timesheet_entries, dependent: :restrict_with_error, autosave: true

  validates_presence_of :prospect_id
  validates_presence_of :tax_week_id
  validates_presence_of :event_id, if: :is_auto_generated?
  validates_presence_of :job_id, if: :is_auto_generated?
  validate :okay_to_submit, if: :is_submitted?

  validates :monday,    inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :tuesday,   inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :wednesday, inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :thursday,  inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :friday,    inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :saturday,  inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :sunday,    inclusion: { in: 0..24, message: "hours must be between 0 and 24" }, allow_nil: true
  validates :rate,      numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deduction, numericality: { greater_than_or_equal_to: 0 }
  validates :allowance, numericality: { greater_than_or_equal_to: 0 }
  validates :status,    inclusion: { in: %w{NEW PENDING SUBMITTED TO_APPROVE}}, allow_nil: false
  validates :type,      inclusion: { in: %w{AUTO MANUAL}}, allow_nil: false

  def is_auto_generated?
    type == 'AUTO'
  end

  def status=(value)
    timesheet_entries.each do |tse|
      tse.status = value
    end
    super(value)
  end

  def is_submitted?
    status == 'SUBMITTED'
  end

  ##### Use by OfficeZoneSync to prepend a string to an error message
  def prepend_error_message
    "• #{prospect.first_name} #{prospect.last_name}#{event ? " / #{event.name}" : ''} : "
  end

  def okay_to_submit
    if type == 'AUTO'
      timesheet_entries.each do |tse|
        if not tse.time_start and not tse.time_end
          errors.add(:base, "Timesheet needs start and end time")
        elsif not tse.time_start
          errors.add(:base, "Timesheet needs start time")
        elsif not tse.time_end
          errors.add(:base, "Timesheet needs end time")
        elsif tse.time_start == tse.time_end
          errors.add(:base, "Timesheet start and end should not be the same")
        end
      end
    else
      unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday, deduction, allowance].reduce {|sum, n| (sum || 0) + (n || 0)} > 0
        errors.add(:base, "No hours, deduction, or allowance entered")
      end
    end
  end
end
