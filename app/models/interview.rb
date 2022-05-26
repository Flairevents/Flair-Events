require 'office_zone_sync'

class Interview < ApplicationRecord
  include OfficeZoneSync

  belongs_to :prospect
  belongs_to :interview_slot
  belongs_to :interview_block

  validates_presence_of :prospect_id, :interview_slot_id
  validates_uniqueness_of :prospect_id

  #######################################################
  ##### Call update_counts method on Interview Slot #####
  #######################################################
  after_update  :update_previous_interview_count_on_interview_slot
  after_commit  :update_interview_count_on_interview_slot
  def update_previous_interview_count_on_interview_slot
    InterviewSlot.find_by_id(self.interview_slot_id_before_last_save).try(:update_interview_counts) if self.saved_change_to_interview_slot_id?
  end
  def update_interview_count_on_interview_slot
    InterviewSlot.find_by_id(self.interview_slot_id).try(:update_interview_counts)
  end
  #######################################################

  def date
    interview_slot.interview_block.date
  end

  def time_start
    interview_slot.time_start
  end

  def time_end
    interview_slot.time_end
  end

  def venue
    interview_slot.interview_block.bulk_interview.venue
  end

  def address
    interview_slot.interview_block.bulk_interview.address
  end

  def city
    interview_slot.interview_block.bulk_interview.city
  end

  def post_code
    interview_slot.interview_block.bulk_interview.post_code
  end

  def directions
    interview_slot.interview_block.bulk_interview.directions
  end

  def note_for_applicant
    interview_slot.interview_block.bulk_interview.note_for_applicant
  end

  def photo_url
    interview_slot.interview_block.bulk_interview.photo ? "/bulk_interview_photos/#{interview_slot.interview_block.bulk_interview.id}.png" : nil
  end

  def type
    interview_slot.interview_block.bulk_interview.interview_type
  end

end
