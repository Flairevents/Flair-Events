# Each Prospect and each Officer has exactly one Account
# Accounts take care of login/logout, authentication, confirming e-mail addresses, etc.
# User permissions are cared for by Prospect/Officer

# For controller authentication/login/logout methods, see lib/authentication.rb

require 'bcrypt'
require 'securerandom'
require 'office_zone_sync'

class Account < ApplicationRecord
  include OfficeZoneSync
  ALLOWED_USER_TYPES = %w[Prospect Officer ClientContact].freeze
  belongs_to :user, polymorphic: true
  has_many :session_logs, dependent: :destroy
  has_many :notifications, foreign_key: 'recipient_id', dependent: :destroy

  validates :user_id, presence: true, numericality: { only_integer: true }
  validates :user_type, presence: true, inclusion: { in: ALLOWED_USER_TYPES }
  validates :user_id, uniqueness: { scope: :user_type }

  # Users can log in by any one of three methods:
  # 1. Entering a password
  # 2. Clicking on a one-time login link (either after first registration, or after forgetting password)

  before_create do
    self.unsubscribe_token = generate_unique_token(:unsubscribe_token)
    self.authentication_token = generate_unique_token(:authentication_token)
  end

  # Password storage and authentication
  PEPPER = "324nm8sdf0,kk"

  def password
    # BCrypt handles generation and storage of salts
    @password ||= password_hash? && ::BCrypt::Password.new(password_hash)
  end
  def password=(password)
    @password = ::BCrypt::Password.create("#{password}#{PEPPER}")
    self.password_hash = @password
  end

  def self.password_valid?(password); why_invalid?(password).nil?;  end
  def password_valid?(password); Account.password_valid?(password); end
  def self.why_invalid?(password)
    if password.blank?
      "Your password can't be blank."
    elsif password =~ /\s/
      "Your password can't include spaces."
    elsif password.length < 8
      "The password you entered is only #{password.length} characters long. To make it more difficult for a hacker to break into your account, please enter a longer password."
    elsif DICTIONARY.include?(password.downcase)
      "The password you entered is a dictionary word. To make it more difficult for a hacker to break into your account, please use a different password."
    elsif password.chars.to_a.uniq.size < 4
      "The password you entered is too repetitive. To make it more difficult for a hacker to break into your account, please use a greater variety of characters."
    end
  end
  def why_invalid?(password); Account.why_invalid?(password); end
  DICTIONARY = Set.new(File.readlines(File.expand_path('../../data/dictionary.txt', __dir__)).map(&:chomp))

  def authenticate_by_password(password)
    self.password == "#{password}#{PEPPER}"
  end

  # One-time login token storage
  def generate_one_time_token!
    self.one_time_token ||= generate_unique_token(:one_time_token)
    save!
  end
  def one_time_token_used!
    self.one_time_token = nil
    save!
  end

  def generate_unique_token(column)
    loop do
      token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
      return token unless Account.where(column => token).exists?
    end
  end

  def okay_to_sync
    self.user_type == 'Officer'
  end
end
