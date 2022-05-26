require 'office_zone_sync'

class Client < ApplicationRecord
  include OfficeZoneSync

  COMPANY_TYPES = ['Event Producer', 'Event Organiser', 'Production Company', 'Bar Operator', 'Ticketing Company', 'Race Directors', 'Venue Managers', 'Brand Managers', 'Operations Company']

  before_destroy :check_if_can_be_destroyed

  has_many :event_clients, dependent: :destroy
  has_many :events, through: :event_clients
  has_many :client_contacts, dependent: :destroy
  has_many :prospects, dependent: :restrict_with_error

  validates_presence_of :name
  validates_uniqueness_of :name
  validate :validate_dates
  validates_format_of :phone_no, with: /\A[0-9]+(\([0-9]+\))?\z/, allow_nil: true
  validates_format_of :email, with: /\A[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, allow_nil: true
  validates_inclusion_of :company_type, in: COMPANY_TYPES, allow_nil: true

  before_validation :strip_blanks

  def strip_blanks
    self.name.try(:strip!)
    self.address.try(:strip!)
    self.phone_no.try(:strip!)
    self.email.try(:strip!)
    self.accountant_email.try(:strip!)
  end

  def validate_dates
    errors.add(:base, "Terms & Conditions Received Date can't be before Sent Date") if terms_date_sent  and terms_date_received  and terms_date_sent  > terms_date_received
    errors.add(:base, "Health & Safety Received Date can't be before Sent Date")    if safety_date_sent and safety_date_received and safety_date_sent > safety_date_received
  end

  def check_if_can_be_destroyed
    if EventClient.where(client_id: id).exists?
      errors.add(:base, "Cannot delete client since it is already associated with events")
    end
    throw :abort unless errors.empty?
  end

end