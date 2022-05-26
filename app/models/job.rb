require 'office_zone_sync'

class Job < ApplicationRecord
  include OfficeZoneSync

  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'

  # ASSOCIATIONS
  belongs_to :event
  has_many   :gigs,          dependent: :restrict_with_error
  has_many   :assignments,   dependent: :restrict_with_error
  has_many   :pay_weeks,     dependent: :restrict_with_error

  # DATA VALIDATION
  validates_presence_of :name, :pay_17_and_under, :pay_18_and_over, :pay_21_and_over, :pay_25_and_over
  validates_uniqueness_of :name, scope: :event_id

  validates_each :pay_17_and_under, :pay_18_and_over, :pay_21_and_over, :pay_25_and_over do |job,attr,value|
    job.errors.add(attr, 'must not be negative') if value && value < 0
  end

  before_destroy do |job|
    event = job.event
    if event.default_job_id == job.id
      event.default_job_id = nil
      throw :abort unless event.save
    end
  end

  def wage_type_for_person(prospect, reference_date)
    age = prospect.age(reference_date)
    return :pay_17_and_under unless age
    if age >= 23
      :pay_25_and_over
    elsif age >= 21
      :pay_21_and_over
    elsif age >= 18
      :pay_18_and_over
    else
      :pay_17_and_under
    end
  end

  def rate_for_person(prospect, reference_date)
    wage_type = wage_type_for_person(prospect, reference_date)
    return 0 unless wage_type
    self.send(wage_type)
  end

  def base_pay_for_person(prospect, reference_date)
    base_pay(wage_type_for_person(prospect, reference_date))
  end

  def holiday_pay_for_person(prospect, reference_date)
    holiday_pay(wage_type_for_person(prospect, reference_date))
  end

  def display_name
    public_name != "" && public_name != nil ? public_name : name
  end

  def base_pay(wage_type)
    raise "Invalid Wage Type" unless valid_wage_type(wage_type)
    value = self.send(wage_type)
     '%.2f' % (BigDecimal.new(value)-BigDecimal.new(holiday_pay(wage_type)))
  end
  ##### Clare stated the holiday pay rate is 12.07%
  ##### According to https://www.gov.uk/calculate-your-holiday-entitlement/y/casual-or-irregular-hours/5.0:
  #####  - https://www.gov.uk/calculate-your-holiday-entitlement/y/casual-or-irregular-hours/5.0
  def holiday_pay(wage_type)
    raise "Invalid Wage Type" unless valid_wage_type(wage_type)
    wage=self.send(wage_type)
    '%.2f' % (BigDecimal.new(BigDecimal.new(wage) - BigDecimal.new(wage)/BigDecimal.new('1.1207')).round(2))
  end
  def valid_wage_type(wage_type)
    [:pay_17_and_under, :pay_18_and_over, :pay_21_and_over, :pay_25_and_over].include? wage_type
  end

  def non_zero_rate?
    [pay_25_and_over, pay_21_and_over, pay_18_and_over, pay_17_and_under].any? {|rate| rate > 0}
  end

  def pretty_name
    self[:public_name].blank? ? self[:name] : self[:public_name]
  end
end
