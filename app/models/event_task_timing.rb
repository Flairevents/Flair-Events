class EventTaskTiming < ApplicationRecord
  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'

  validates_presence_of :type, :template_id, :size_id, :days
  belongs_to :template, class_name: 'EventTaskTemplate', foreign_key: 'template_id'
  belongs_to :size, class_name: 'EventSize', foreign_key: 'size_id'
  TYPES = %w{BEFORE_EVENT_START}.freeze
  validates :type, inclusion: { in: TYPES }
end
