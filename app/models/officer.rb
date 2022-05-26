require 'office_zone_sync'

class Officer < ApplicationRecord
  include OfficeZoneSync

  has_one :account, as: :user, dependent: :destroy, autosave: true
  has_many :team_leader_roles, dependent: :restrict_with_error, as: :user
  has_many :events, dependent: :restrict_with_error, foreign_key: :office_manager
  has_many :event_tasks, dependent: :restrict_with_error

  validates :email, presence: true, uniqueness: true, format: { with: /\A[^@]+@[^@]+\.[^@]+\z/ }
  validates_presence_of :first_name, :last_name, :role
  validates_uniqueness_of :email

  def admin?;   role == 'admin'; end
  def manager?; admin? || role == 'manager'; end
  def staffer?; role == 'staffer'; end
  def archived?; role == 'archived'; end

  def allowTimeClockingAppLogin?
    true
  end
end
