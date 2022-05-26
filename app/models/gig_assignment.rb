require 'office_zone_sync'
require 'sync_attributes'

class GigAssignment < ApplicationRecord
  include OfficeZoneSync
  include SyncAttributes

  belongs_to :gig
  belongs_to :assignment
  delegate :event, to: :gig
  delegate :prospect, to: :gig
  delegate :shift, to: :assignment
  delegate :job, to: :assignment
  delegate :location, to: :assignment
  has_one :timesheet_entry, dependent: :restrict_with_error

  validates_presence_of :gig_id, :assignment_id

  validates_uniqueness_of :assignment_id, scope: :gig_id

  ###################################################
  ##### Call update_counts method on Assignment ##### 
  ###################################################
  after_update  :update_previous_staff_counts_on_assignment
  after_commit  :update_staff_counts_on_assignment
  def update_previous_staff_counts_on_assignment
    Assignment.find_by_id(self.assignment_id_before_last_save).try(:update_staff_counts) if self.saved_change_to_assignment_id?
  end
  def update_staff_counts_on_assignment
    Assignment.find_by_id(self.assignment_id).try(:update_staff_counts)
  end
  ###################################################

  def date
    assignment.shift.date
  end

  def prospect_id
    prospect.id
  end	  

  def event_id
    event.id
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({ :methods => [:date, :prospect_id, :event_id] }))
  end
end
