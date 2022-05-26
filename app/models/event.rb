require 'has_post_code'
require 'office_zone_sync'

class Event < ApplicationRecord
  include HasPostCode
  include OfficeZoneSync

  before_destroy :check_if_can_be_destroyed

  # ASSOCIATIONS
  belongs_to :event_category, foreign_key: :category_id, optional: true
  belongs_to :default_job, class_name: 'Job', foreign_key: :default_job_id, optional: true
  belongs_to :default_location, class_name: 'Location', foreign_key: :default_location_id, optional: true
  belongs_to :default_assignment, class_name: 'Assignment', foreign_key: :default_assignment_id, optional: true
  belongs_to :region, optional: true
  belongs_to :office_manager, class_name: 'Officer', foreign_key: 'office_manager_id', optional: true
  belongs_to :size, class_name: 'EventSize', foreign_key: :size_id, optional: true
  has_many   :assignments,  dependent: :destroy
  has_many   :jobs,         dependent: :destroy
  has_many   :shifts,       dependent: :destroy
  has_many   :locations,    dependent: :destroy
  has_many   :tags,         dependent: :destroy
  has_many   :gigs,         dependent: :restrict_with_error
  has_many   :gig_requests, dependent: :destroy
  has_many   :bulk_interview_events, dependent: :destroy
  has_many   :bulk_interviews, through: :bulk_interview_events
  has_many   :event_clients, dependent: :destroy
  has_many   :bookings, through: :event_clients, dependent: :destroy
  has_many   :clients, through: :event_clients
  has_many   :invoices, through: :event_clients, dependent: :restrict_with_error
  has_many   :pay_weeks, dependent: :restrict_with_error
  has_many   :assignment_email_templates, dependent: :destroy
  has_many   :time_clock_reports, dependent: :restrict_with_error
  has_many   :team_leader_roles, dependent: :destroy
  has_many   :event_dates, dependent: :destroy
  has_many   :event_tasks, dependent: :destroy
  has_many   :team_leader_roles, dependent: :destroy
  has_many   :expenses, dependent: :destroy
  has_many   :action_takens, dependent: :destroy
  has_many   :reject_events, dependent: :destroy

  before_validation :set_public_dates

  # DATA VALIDATION
  validates_presence_of :name, :display_name, :status, :date_start, :date_end
  validates_presence_of :office_manager, if: :size_id?, message: "needed in order to set a Size"
  validate :validate_post_code
  validate :validate_category_id
  validate :validate_dates
  validate :validate_leader_meeting_location_coords

  validates_format_of :website, with: /\A(?:https?:\/\/)?[\w.\-]+(?:\.[\w\.\-]+)+[\w\-\._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+\z/, allow_nil: true, allow_blank: true
  validates_uniqueness_of :name
  validates :additional_staff, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :staff_needed, numericality: {only_integer: true, greater_than_or_equal_to: 0, allow_nil: true}
  validates :leader_flair_phone_no, numericality: {only_integer: true}, length: 10..11, allow_blank: true

  before_validation :strip_blanks

  STATUSES = %w{BOOKING NEW OPEN CANCELLED HAPPENING FINISHED CLOSED}.freeze
  validates_inclusion_of :status, in: STATUSES
  FULLNESS = %w{OPEN REGISTER_INTEREST FULL NEARLY}.freeze
  validates :fullness, inclusion: { in: FULLNESS }
  ACCOM_STATUSES = %w{NONE NEED BOOKED CANCELLED REFUND}.freeze
  validates :accom_status, inclusion: {in: ACCOM_STATUSES}

  STATUSES.each do |status|
    define_method("#{status.downcase}?".to_sym) { self.status == status }
  end

  def self.current_year_number_of_events
	  Event.where(created_at:  Time.current.beginning_of_year..Time.current).size
  end


  after_create do |event|
    AssignmentEmailTemplate.create(event_id: event.id, name: 'Default')
  end

  before_save do |event|
    event.update_history_tr
    event.update_next_active_date if !event.next_active_date || event.public_date_start_changed? || event.date_start_changed?
  end

  def set_public_dates
    self.public_date_start = date_start if date_start and (!public_date_start || public_date_start < date_start)
    self.public_date_end   = date_end   if date_end   and (!public_date_end   || public_date_end > date_end)
  end

  def validate_dates
    errors.add(:date_start,        "can't be after End Date")        if date_start and date_end               and date_start > date_end
    errors.add(:public_date_start, "can't be after Public End Date") if public_date_start and public_date_end and public_date_start > public_date_end
    all_event_dates = event_dates.pluck(:date).sort
    if all_event_dates.any?
      errors.add(:date_start, "cannot be after calendar event days")  if date_start and date_start > all_event_dates.first
      errors.add(:date_end,   "cannot be before calendar event days") if date_end   and date_end   < all_event_dates.last
    else
      # a bit of a hack, but we only run this check on events create after 2013-04-06, which is when the new office zone launched
      # legacy events don't have defined tax weeks or validate dates for event dates
      errors.add(:base, "You must select at lease one date on the event calendar") unless new_record? || status == 'CANCELLED' || date_start < Date.new(2013, 04, 06)
    end
  end

  # Make data validation messages appear in a more natural, grammatical way
  def self.human_attribute_name(attribute,options={})
    {date_start: 'Start Date', date_end: 'End Date', public_date_start: 'Public Start Date', public_date_end: 'Public End Date', leader_flair_phone_no: 'Flair Contact Phone Number'}[attribute] || super
  end

  #Save the date when the status is changed to open.
  #This is used to mark newly opened events in the staff zone
  def status=(value)
    write_attribute(:date_opened, Date.today()) if status != 'OPEN' && value == 'OPEN'
    write_attribute(:status, value)
  end

  # Sometimes the office staff adjusts the end date, or the server gets restarted and the cron job doesn't happen.
  # In these cases, adjust the FINISHED/HAPPENING status accordingly
  def date_end=(value)
    write_attribute(:status, 'FINISHED') if status == 'HAPPENING' && Date.parse(value) < Date.today
    write_attribute(:status, 'HAPPENING') if status == 'FINISHED' && Date.parse(value) > Date.today
    write_attribute(:date_end, value)
  end

  # SCOPES
  scope :open, -> { where(status: ['OPEN', 'HAPPENING']) }
  scope :upcoming, ->  { where('date_start > ?', Date.today).order('next_active_date ASC') }
  scope :visible, -> { where(status: ['OPEN', 'HAPPENING']) } # visible to PROSPECTS. Officers can see all Events
  scope :not_finished, -> { where('date_end >= ?', Date.today).order('next_active_date ASC') }

  def self.this_year; where('extract(year from public_date_start) = ?', Date.today.year); end

  ##### The following date printing methods are all used for the public, so they use the public dates
  def duration_for_show
    unless show_in_ongoing
      date_start_for_show = [public_date_start, Date.today].max
      duration = event_dates.where("date >= ?", date_start_for_show).count
      return "#{duration.to_i} day#{'s' if duration > 1}"
    else
      return "Ongoing"
    end
  end

  def date_range_for_show
    date_start_for_show = [public_date_start, Date.today].max
    date_end_for_show = public_date_end
    unless show_in_ongoing
      if date_start_for_show != date_end_for_show
        if date_start_for_show.year == date_end_for_show.year && date_start_for_show.month == date_end_for_show.month
          "#{date_start_for_show.for_show_a_d_o_m} - #{date_end_for_show.for_show_a_d_o_m}"
        elsif date_start_for_show.year == date_end_for_show.year
          "#{date_start_for_show.for_show_a_d_o_m} - #{date_end_for_show.for_show_a_d_o_m}"
        else
          "#{date_start_for_show.for_show_a_d_m_y} - #{date_end_for_show.for_show_a_d_m_y}"
        end
      else
        date_start_for_show.for_show_a_d_o_m
      end
    else
      "#{date_start_for_show.for_show_a_d_o_m} - Ongoing"
    end
  end

  def date_range_for_show_mobile
    date_start_for_show = [public_date_start, Date.today].max
    date_end_for_show = public_date_end
    unless show_in_ongoing
      if date_start_for_show != date_end_for_show
        if date_start_for_show.year == date_end_for_show.year && date_start_for_show.month == date_end_for_show.month
          "#{date_start_for_show.for_show_a_d_o_m_mobile} - #{date_end_for_show.for_show_a_d_o_m_mobile}"
        elsif date_start_for_show.year == date_end_for_show.year
          "#{date_start_for_show.for_show_a_d_o_m_mobile} - #{date_end_for_show.for_show_a_d_o_m_mobile}"
        else
          "#{date_start_for_show.for_show_a_d_m_y} - #{date_end_for_show.for_show_a_d_m_y}"
        end
      else
        date_start_for_show.for_show_a_d_o_m_mobile
      end
    else
      "#{date_start_for_show.for_show_a_d_o_m_mobile} - Ongoing"
    end
  end

  def date_range_for_show_no_year
    if public_date_start != public_date_end
      if public_date_start.year == public_date_end.year && public_date_start.month == public_date_end.month
        "#{public_date_start.for_show_a_d} - #{public_date_end.for_show_a_d_m}"
      else
        "#{public_date_start.for_show_a_d_m} - #{public_date_end.for_show_a_d_m}"
      end
    else
      public_date_start.for_show_a_d_m
    end
  end

  def date_range_for_history
    if public_date_start != public_date_end
      if public_date_start.year == public_date_end.year && public_date_start.month == public_date_end.month
        "#{public_date_start.for_show_d}-#{public_date_end.for_show_d_m}"
      elsif public_date_start.year == public_date_end.year
        "#{public_date_start.for_show_d_m} - #{public_date_end.for_show_d_m}"
      else
        "#{public_date_start.for_show} - #{public_date_end.for_show_d_m}"
      end
    else
      public_date_start.for_show_d_m
    end
  end

  def date_range_as_phrase
    if public_date_start != public_date_end
      "from #{public_date_start.to_print} to #{public_date_end.to_print}"
    else
      "on #{public_date_start.to_print}"
    end
  end

  # Size which we will convert Event photos to:
  EVENT_THUMBNAIL_SIZE = {width: 100, height: 100}

  def photo_url
    photo ? "/event_photos/#{photo}" : "/assets/no-event-photo.jpg"
  end

  def display_name_with_location
    if location && !display_name.include?(location)
      "#{display_name} (#{location})"
    else
      display_name
    end
  end

  def validate_post_code
    unless status == 'BOOKING' || status == 'NEW' || status == 'CANCELLED'
      if post_code
        if post_code_changed?
          errors.add(:base, "Post Code is not recognized") unless region_id_from_post_code #'region' is from has_post_code module.
        end
      else
        errors.add(:post_code, "can't be blank")
      end
    end
  end

  def validate_category_id
    errors.add(:base, "Category must be selected") if status != 'BOOKING' && !category_id
  end

  def validate_leader_meeting_location_coords
    unless leader_meeting_location_coords.blank?
      coords = leader_meeting_location_coords.split(',')
      unless coords.length == 2 and coords[0].is_numeric? and coords[1].is_numeric?
        errors.add(:base, "Leader Meeting Location Coords are not valid coordinates")
      end
    end
  end

  def strip_blanks
    self.name = self.name.try(:strip)
  end

  def check_if_can_be_destroyed
    unless ['NEW', 'CANCELLED', 'BOOKING', 'OPEN'].include? status
      errors.add(:base, "Can Only Delete Events in New, Cancelled, Booking, or Open Status")
    end
    throw :abort unless errors.empty?
  end

  def invoice_this_tax_week?(tax_week)
    self.event_dates.where('? <= date AND date <= ?', tax_week.date_start, tax_week.date_end).any?
  end

  def invoice(tax_week)
    event_clients.each do |event_client|
      unless Invoice.where(event_client: event_client, tax_week: tax_week).any?
        invoice = Invoice.new
        invoice.event_client_id = event_client.id
        invoice.tax_week_id = tax_week.id
        invoice.status = 'NEW'
        invoice.save
      end
    end
  end

  def invoice_if_needed(tax_week)
    invoice(tax_week) if invoice_this_tax_week?(tax_week)
  end

  def update_history_tr
    self.history_tr = "<tr style='vertical-align:bottom'><td>#{display_name}</td><td>#{location}</td><td class='text-nowrap'>#{date_range_for_history}</td><td>#{additional_staff + gigs_count}</td></tr>"
  end

  def update_gigs_count
    self.update_attribute(:gigs_count, self.gigs.size)
  end

  def update_next_active_date
    dates = ([self.public_date_start] + self.event_dates.pluck(:date)).select { |date| date >= Date.today }.sort
    self.next_active_date = dates.any? ? dates.first : self.public_date_start || self.date_start
  end
end
