require 'office_zone_sync'

class EventTask < ApplicationRecord

  include OfficeZoneSync

  belongs_to :event, optional: true
  belongs_to :officer
  belongs_to :second_officer, class_name: "Officer", foreign_key: "second_officer_id", optional: true
  belongs_to :template, class_name: 'EventTaskTemplate', foreign_key: 'template_id', optional: true
  belongs_to :tax_week

  validates_presence_of :officer_id, :due_date, :tax_week

  before_validation do |event_task|
    if event_task.due_date && (tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', event_task.due_date, event_task.due_date).first)
      event_task.tax_week_id = tax_week.id
    end

    if event_task.completed_changed?
      if event_task.completed
        event_task.completed_date = Date.today
      else
        event_task.completed_date = nil
      end
    end
  end
  
end
