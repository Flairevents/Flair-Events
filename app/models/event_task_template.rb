class EventTaskTemplate < ApplicationRecord
  validates_presence_of :task
  validates_uniqueness_of :task
  has_many :event_task_timings, dependent: :restrict_with_error
end
