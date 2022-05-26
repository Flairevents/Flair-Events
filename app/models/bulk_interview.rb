require 'has_post_code'
require 'office_zone_sync'

class BulkInterview < ApplicationRecord
  include HasPostCode
  include OfficeZoneSync

  belongs_to :target_region, class_name: 'Region', foreign_key: :target_region_id, optional: true
  belongs_to :region, optional: true

  has_many :bulk_interview_events, dependent: :destroy
  has_many :events, through: :bulk_interview_events
  has_many :interview_blocks, dependent: :destroy

  validates_presence_of :name, :date_start, :date_end, :interview_type, :venue

  validate :validate_dates
  validate :validate_date_start
  validate :validate_date_end
  validate :validate_start_and_end_dates
  validate :validate_existing_interviews
  validate :validate_has_interview_blocks_for_open

  STATUSES = %w{NEW OPEN FINISHED}.freeze
  validates_inclusion_of :status, in: STATUSES

  TYPES = %w{IN_PERSON ONLINE}.freeze
  validates_inclusion_of :interview_type, in: TYPES, allow_nil: true

  # Size which we will convert Event photos to:
  THUMBNAIL_SIZE = {width: 300, height: 300}

  def validate_has_interview_blocks_for_open
    errors.add(:base, "You must create at least one interview block in order to open up this interview") if status == 'OPEN' && interview_blocks.none?
  end

  def validate_dates
    errors.add(:base, "You must enter a 'week of' date") unless date_start && date_end
  end

  def validate_date_start
    (errors.add(:date_start, " must be a Monday") unless date_start.wday == 1) if date_start
  end

  def validate_date_end
    (errors.add(:date_end, " must be a Sunday") unless date_end.wday == 0) if date_end
  end

  def validate_start_and_end_dates
    (errors.add(:base, "Date start and end must span exactly one week, from Monday to Sunday") unless (date_end - date_start).to_i == 6) if date_start && date_end
  end

  def validate_existing_interviews
    if id && date_start && date_end && Interview.joins([:interview_slot, "INNER JOIN interview_blocks ON interview_slots.interview_block_id = interview_blocks.id", "INNER JOIN bulk_interviews ON interview_blocks.bulk_interview_id = bulk_interviews.id"]).where('bulk_interviews.id = ? AND ((interview_blocks.date < ?) OR (interview_blocks.date > ?))', id, date_start, date_end).exists? then
      errors.add(:base, "Cannot change the dates as there are already interviews scheduled for these dates")
    end
  end

  def photo_url
    photo ? "/bulk_interview_photos/#{photo}" : "/assets/no-event-photo.jpg"
  end

  def has_events?
    BulkInterviewEvent.where(bulk_interview_id: id).exists?
  end
end
