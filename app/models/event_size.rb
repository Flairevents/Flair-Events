class EventSize < ApplicationRecord
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :todo_task_event_sizes, dependent: :restrict_with_error
  has_many :events, foreign_key: :size_id, dependent: :restrict_with_error
end
