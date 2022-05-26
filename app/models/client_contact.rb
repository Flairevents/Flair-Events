require 'office_zone_sync'

class ClientContact < ApplicationRecord
  include OfficeZoneSync

  belongs_to :client
  has_one :account, dependent: :destroy, as: :user
  has_many :bookings, dependent: :restrict_with_error
  has_many :team_leader_roles, dependent: :restrict_with_error, as: :user

  validates_presence_of :first_name, :last_name, :email, :client_id
  validates_uniqueness_of :email, scope: :client_id

  validates_format_of :mobile_no, with: /\A[0-9]+(\([0-9]+\))?\z/, allow_nil: true
  validates_format_of :email, with: /\A[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, allow_nil: true

  ACCOUNT_STATUSES = %w{NEW INVITED CONFIRMED_EMAIL ACTIVATED}.freeze
  validates_inclusion_of :account_status, in: ACCOUNT_STATUSES

  before_validation :strip_blanks

  def strip_blanks
    self.first_name.try(:strip!)
    self.last_name.try(:strip!)
    self.mobile_no.try(:strip!)
    self.email.try(:strip!)
  end

  def company_name
    client.name
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({ :methods => [:company_name] }))
  end

  def allowTimeClockingAppLogin?
    true
  end

  def account_activated?
    account_status == 'ACTIVATED'
  end
end
