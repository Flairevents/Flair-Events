require 'office_zone_sync'

class InterviewBlock < ApplicationRecord
  include OfficeZoneSync
  belongs_to :bulk_interview
  has_many :interview_slots, dependent: :destroy

  validates_presence_of :bulk_interview_id, :date, :time_start, :time_end, :slot_mins, :number_of_applicants_per_slot

  validates_numericality_of :slot_mins, only_integer: true, greater_than: 0, message: 'Must be greater than zero', allow_nil: true
  validates_numericality_of :number_of_applicants_per_slot, only_integer: true, greater_than_or_equal_to: 0, message: 'Must  not be negative', allow_nil: true

  validate :start_time_before_end_time
  validate :slot_mins_fits_evenly_in_total_time
  validate :time_range
  # validate :overlapping_slots
  validate :interview_block_details
  validate :removed_slots_dont_have_scheduled_interviews

  # Make data validation messages appear in a more natural, grammatical way
  def self.human_attribute_name(attribute,options={})
    {slot_mins: 'Slot Minutes'}[attribute] || super
  end

  def start_time_before_end_time
    if time_end && time_start
      errors.add(:base, "End time should be after start time") unless time_end > time_start
    end
  end

  def slot_mins_fits_evenly_in_total_time
    if time_end && time_start && slot_mins
      errors.add(:slot_mins, "must fit evenly in total time") unless ((time_end.to_i-time_start.to_i)/60).round % slot_mins == 0
    end
  end

  def time_range
    if time_start && time_end
      minimum = Time.utc(time_start.year, time_start.month, time_start.day, 8,0,0)
      maximum = Time.utc(time_end.year,   time_end.month,   time_end.day, 21,0,0)
      unless (time_start >= minimum) && (time_end   <= maximum)
        errors.add(:base, "Time range must be between 8am and 9pm")
      end
    end
  end

  def interview_block_details
    if is_morning == false && is_afternoon == false && is_evening == false
      errors.add(:base, "Please choose at least one schedule time")
    end 

    if is_morning == true && (morning_applicants == 0 || morning_applicants == nil)
      errors.add(:base, "Please put fill up the number of applicants in morning")
    end

    if is_afternoon == true && (afternoon_applicants == 0 || afternoon_applicants == nil)
      errors.add(:base, "Please put fill up the number of applicants in afternoon")
    end

    if is_evening == true && (evening_applicants == 0 || evening_applicants == nil)
      errors.add(:base, "Please put fill up the number of applicants in evening")
    end

    if morning_applicants != nil
      if morning_applicants > 0 && is_morning == false
        errors.add(:base, "Please check the morning checkbox")
      end
    end

    if afternoon_applicants != nil
      if afternoon_applicants > 0 && is_afternoon == false
        errors.add(:base, "Please check the afternoon checkbox")
      end
    end

    if evening_applicants != nil
      if evening_applicants > 0 && is_evening == nil
        errors.add(:base, "Please check the evening checkbox")
      end
    end
  end

  def overlapping_slots
    if time_end && time_start && date
      id_clause = id ? "interview_blocks.id NOT IN (#{id}, -1)" : "(interview_blocks.id IS NOT NULL AND interview_blocks.id <> -1)"
      ibs = InterviewBlock.joins(:bulk_interview).where("#{id_clause} AND date = ? AND (time_start < ? AND time_end > ?) AND bulk_interviews.interview_type = ?", date, time_end, time_start, bulk_interview.interview_type)
      if ibs.length > 0
        msg = "Interview slots cannot overlap other interview slots:\n"
        ibs.each do |ib|
          msg << "- #{ib.bulk_interview.name}: #{ib.date.to_print} #{ib.time_start.strftime("%H:%M")} to #{ib.time_end.strftime("%H:%M")}\n"
        end
        errors.add(:base, msg)
      end
    end
  end

  def full?
    max_appli = self.interview_slots.count * self.number_of_applicants_per_slot
    current_appli = self.interview_slots.pluck('interviews_count').sum
    if current_appli < max_appli
      false 
    else
      true
    end
  end

  def removed_slots_dont_have_scheduled_interviews
    if id
      earlier_slots_to_remove = InterviewSlot.where('interview_block_id = ? AND time_start < ?', id, time_start)
      earlier_interviews = Interview.where(interview_slot_id: earlier_slots_to_remove.pluck(:id))
      if earlier_interviews.length > 0
        errors.add(:base, "Cannot move start time forward as there are already interviews scheduled for #{earlier_interviews.map { |i| i.interview_slot.time_start }.uniq.sort.map {|t| t.strftime("%H:%M")}.join(", ")}")
      end
      later_slots_to_remove = InterviewSlot.where('interview_block_id = ? AND time_end > ?', id, time_end)
      later_interviews = Interview.where(interview_slot_id: later_slots_to_remove.pluck(:id))
      if later_interviews.length > 0
        errors.add(:base, "Cannot move end time backward as there are already interviews scheduled for #{later_interviews.map { |i| i.interview_slot.time_start }.uniq.sort.map {|t| t.strftime("%H:%M")}.join(", ")}")
      end
    end
  end
end