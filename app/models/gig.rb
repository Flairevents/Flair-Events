require 'office_zone_sync'

class Gig < ApplicationRecord
  include OfficeZoneSync

  scope :published,   -> { where published: true  }
  scope :unpublished, -> { where published: false }

  belongs_to :prospect
  belongs_to :event
  belongs_to :job, optional: true
  belongs_to :location, optional: true
  has_many :gig_assignments, dependent: :destroy
  has_many :unworked_gig_assignments, dependent: :restrict_with_error
  has_many :assignments, through: :gig_assignments
  has_many :timesheet_entries, through: :gig_assignments
  has_many :gig_tags, dependent: :destroy
  has_many :tags, through: :gig_tags
  has_one :gig_request, dependent: :nullify
  has_many :gig_tax_weeks, dependent: :destroy

  validates_presence_of :prospect_id, :event_id
  validates_inclusion_of :status, in: %w{Active Inactive}
  validates_inclusion_of :rating, :in => 1..5, allow_nil: true, message: 'must be from 1 to 5'

  ##############################################
  ##### Call update_counts method on Event #####
  ##############################################
  after_update :update_previous_gigs_count_on_event
  after_commit :update_gigs_count_on_event
  def update_previous_gigs_count_on_event
    Event.find_by_id(self.event_id_before_last_save).try(:update_gigs_count) if self.saved_change_to_event_id?
  end
  def update_gigs_count_on_event
    Event.find_by_id(self.event_id).try(:update_gigs_count)
  end
  #######################################################

  def request
    GigRequest.where(gig_id: self.id).first
  end

  def rating_comment
    if rating
      "#{rating} - " +
      case rating.round
        when 1
          "Poor Performance - something wrong?"
        when 2
          "Needs improvement - you want to chat?"
        when 3
          "A great asset to the Flair team – thank you"
        when 4
          "Fantastic Job, we think you're great!"
        when 5
          "You are AMAZING, don’t leave us please... ever!"
      end
    else
      ''
    end
  end

  def period
    event.date_range_as_phrase
  end
end