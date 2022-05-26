require 'office_zone_sync'

class InterviewSlot < ApplicationRecord
  include OfficeZoneSync

  belongs_to :interview_block
  has_many :interviews, dependent: :restrict_with_error

  validates_presence_of :interview_block_id, :time_start, :time_end

  def date
    interview_block.date
  end

  def max_applicants
    interview_block.number_of_applicants_per_slot
  end

  def type
    interview_block.bulk_interview.interview_type
  end

  def update_interview_counts
    self.update_attribute(:interviews_count, self.interviews.size)
  end
end