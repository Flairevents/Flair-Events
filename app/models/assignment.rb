require 'office_zone_sync'

class Assignment < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event
  belongs_to :job
  belongs_to :shift
  belongs_to :location
  has_many :gig_assignments, dependent: :restrict_with_error
  has_many :unworked_gig_assignments, dependent: :restrict_with_error
  has_many :gigs, through: :gig_assignments

  validates_presence_of :event_id, :job_id, :shift_id, :location_id, :staff_needed, :staff_count
  validates_uniqueness_of :job_id, scope: [:event_id, :location_id, :shift_id], message: "This assignment combination already exists"

  after_destroy do |assignment|
    if (event = Event.find_by_default_assignment_id(assignment.id))
      event.default_assignment_id = nil
      event.save
    end
  end

  def self.current_year_number_of_assignments
    Assignment.where(created_at:  Time.current.beginning_of_year..Time.current).size
  end

  def to_print_without_date
    "#{job.name} @ #{location.to_print} (#{shift.to_print_time_span})"
  end

  def to_print_with_staff_count_without_date
    "#{job.name} x #{staff_needed} @ #{location.to_print} (#{shift.to_print_time_span})"
  end

  def to_print_with_stats_without_date
    to_print_without_date + (confirmed_staff_count > 0 ? " #{confirmed_staff_count}✓" : '') + " #{staff_count}/#{staff_needed}"
  end

  def date
    shift.date
  end

  ##### This is manually called by any models whose change would affect assignment counts
  def update_staff_counts
    self.update_attribute(:staff_count, self.gig_assignments.size)
    ##### Test this
    self.update_attribute(:confirmed_staff_count, self.gig_assignments.joins(:gig).joins(:assignment).joins('INNER JOIN shifts ON assignments.shift_id = shifts.id').joins('INNER JOIN gig_tax_weeks ON gig_tax_weeks.tax_week_id = shifts.tax_week_id AND gig_tax_weeks.gig_id = gigs.id').where('gig_tax_weeks.confirmed IS true').size)
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({ :methods => [:date] }))
  end

end