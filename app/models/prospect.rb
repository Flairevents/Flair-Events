require 'has_post_code'
require 'brightpay'
require 'office_zone_sync'
require 'user_info'
include Brightpay

class Prospect < ApplicationRecord
  include HasPostCode
  include OfficeZoneSync

  # ASSOCIATIONS
  belongs_to :nationality, class_name: 'Country', optional: true
  belongs_to :client, optional: true
  belongs_to :region, optional: true

  has_many   :details_history, dependent: :destroy
  has_many   :change_requests, dependent: :destroy
  has_many   :gigs,            dependent: :restrict_with_error
  has_many   :gig_requests,    dependent: :destroy
  has_one    :questionnaire,   dependent: :destroy
  has_many   :scanned_dbses,   dependent: :destroy
  has_many   :scanned_ids,     dependent: :destroy
  has_many   :scanned_bar_licenses, dependent: :destroy
  has_many   :share_code_files,   dependent: :destroy
  has_many   :pay_weeks, dependent: :restrict_with_error
  has_many   :pay_week_details_history, dependent: :restrict_with_error
  has_many   :payroll_activities, dependent: :destroy
  has_one    :account,         dependent: :destroy, as: :user
  has_one    :interview,       dependent: :destroy
  has_many   :team_leader_roles, dependent: :restrict_with_error, as: :user
  has_many   :action_takens, dependent: :destroy
  has_many   :reject_events, dependent: :destroy

  # DATA VALIDATION

  validates :email, presence: true, uniqueness: {case_sensitive: false}, format: { with: /\A[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ }
  validates_uniqueness_of :etihad_id_number, allow_nil: true
  validates_presence_of :first_name, :last_name, :status
  validates_presence_of :client_id, if: :external_employee?
  validates_inclusion_of :gender, in: %w{M F}, allow_nil: true
  validates_inclusion_of :tax_choice, in: %w{A B C}, allow_nil: true
  validates_inclusion_of :bar_experience, in: %w{Full Part None}, allow_nil: true
  validates_inclusion_of :training_type, in: %w{FoodSafety HealthAndSafety Both}, allow_nil: true
  validates_format_of :mobile_no, with: /\A[0-9]+(\([0-9]+\))?\z/, allow_nil: true
#  validates_format_of :home_no, with: /\A[0-9]+(\([0-9]+\))?\z/, allow_nil: true
  validates_format_of :emergency_no, with: /\A[0-9]+(\([0-9]+\))?\z/, allow_blank: true
  validates_format_of :ni_number, with: /\A[A-CEGHJ-NOPR-TW-Z][A-CEGHJ-NPR-TW-Z][0-9]{6}[A-D\s]\z/i, allow_nil: true
  validates_format_of :ni_number, without: /\A(GB|BG|NK|KN|TN|NT|ZZ)/i, allow_nil: true
  validates_format_of :address, without: /\[|\]/, message: 'cannot contain square brackets'  # this is so we can export to a payroll program called 12Pay
  validates_format_of :address2, without: /\[|\]/, message: 'cannot contain square brackets'
  # again, for export, the bank account name has to conform to the BACS 18 format
  validates_format_of :bank_account_name, without: /[^A-Z0-9&.\/ -]/, allow_nil: true, message: 'can only contain upper-case letters, numbers, spaces, or any of the following characters: &, ., /, or -'
  validates_length_of :bank_sort_code, is: 6, allow_nil: true
  validates_length_of :bank_account_no, is: 8, allow_nil: true
  validates_format_of :share_code, with: /[A-Za-z0-9]{9}/, allow_nil: true
  validates_length_of :share_code, is: 9, allow_nil: true
  validates_format_of :bank_account_no, without: /\*/
  validates_inclusion_of :country, in: %w{england wales scotland n-ireland non-uk}, allow_nil: true
  MANAGER_LEVELS = ['Level 1', 'Level 2', 'Level 3', 'Level 4', 'C1', 'C2', 'C3'].freeze
  validates_inclusion_of :manager_level, in: ['']+MANAGER_LEVELS, allow_nil: true
  ID_TYPES = ['UK Passport', 'EU Passport', 'Work/Residency Visa', 'BC+NI', 'Pass Visa'].freeze
  validates_inclusion_of :id_type, in: ID_TYPES, allow_nil: true
  DBS_TYPES = ['Basic', 'Enhanced', 'Enhanced Barred List'].freeze
  validates_inclusion_of :dbs_qualification_type, in: DBS_TYPES, allow_nil: true
  CONDITIONS = ['None', 'Holidays', 'Under 20Hrs', 'Specific'].freeze
  validates_inclusion_of :condition, in: CONDITIONS, allow_nil: true

  scope :city_of_study, -> (status) { where("status = (?) and city_of_study != (?)", status, '').select(:city_of_study).distinct.order(city_of_study: :ASC) }
  scope :other_nationality, -> { joins(:nationality).where.not(countries: { name: [Country::UNITED_KINGDOM, Country::IRELAND] }) }
  scope :uk_roi_nationality, -> { joins(:nationality).where(countries: { name: [Country::UNITED_KINGDOM, Country::IRELAND] }) }

  # Make data validation messages appear in a more natural, grammatical way
  def self.human_attribute_name(attribute,options={})
    {address: 'Street Address',
     address2: 'Address Town',
     bank_account_no: 'Bank Account Number',
     emergency_no: 'Emergency Number',
     home_no: 'Home Number',
     id_expiry: 'ID Expiry',
     id_number: 'ID Number',
     id_type: 'ID Type',
     mobile_no: 'Mobile Number',
     share_code: 'Share Code',
     ni_number: 'NI Number'}[attribute] || super
  end

  def self.current_year_number_of_employees
    Prospect.where(created_at: Time.current.beginning_of_year..Time.current, status: 'EMPLOYEE').size
  end

  # HOOKS
  before_save do |prospect|
    prospect.client_id = nil unless status == 'EXTERNAL'

    if prospect.post_code.present?
      if prospect.post_code_changed?
        if region = prospect.region
          prospect.country = {
            'London' => 'england',
            'Yorkshire' => 'england',
            'Wales' => 'wales',
            'Northeast' => 'england',
            'Northwest' => 'england',
            'Southeast' => 'england',
            'Southwest' => 'england',
            'Eastern' => 'england',
            'Midlands' => 'england',
            'Scotland' => 'scotland',
            'Ireland' => 'n-ireland', # all the 'Ireland' postal regions in our DB are actually Northern Ireland
            'East Midlands' => 'england'
          }[region.name]
        end
      end
    else
      #If there's no postal code, then use the nationality to set the country.
      if prospect.nationality_id_changed? && prospect.nationality_id.present?
        if prospect.nationality.name != 'United Kingdom'
          prospect.country = 'non-uk'
        end
      end
    end

    if prospect.bank_account_name_changed? && prospect.bank_account_name.present?
      prospect.bank_account_name.upcase!
    end

    ##### Save Details History
    DetailsHistory.tracked_columns.each do |column|
      if prospect.send("#{column}_changed?".to_sym)
        prev_val, new_val = prospect.send("#{column}_change".to_sym)
        if prospect.send(column).class == FalseClass || prospect.send(column).class == TrueClass
          prev_val = prev_val ? 'Yes' : 'No'
          new_val  = new_val  ? 'Yes' : 'No'
        end
        ###### Log if: (Prev is blank and there is details history) OR (Prev not blank and new_val not blank)
        if (prev_val.blank? && details_history.where(column: column).any?) || !((prev_val.blank? && prev_val != false) || (new_val.blank? && new_val != false))
          user = UserInfo.current_user
          dh = DetailsHistory.new(
            prospect_id: id,
            column: column,
            prev_value: prev_val,
            new_value: new_val,
            changed_by: user ? "#{user.first_name} #{user.last_name}" : 'Unknown'
          )
          dh.save
        end
      end
    end
  end

  # Each Prospect also has a "status". What operations can be performed for a Prospect
  #   depend largely on their current status
  STATUSES = %w{APPLICANT EMPLOYEE HAS_BEEN SLEEPER DEACTIVATED IGNORED EXTERNAL}.freeze
  validates_inclusion_of :status, in: STATUSES

  APPLICANT_STATUSES = %w{UNCONFIRMED HOLDING LIVE ACTIVE}.freeze
  validates_inclusion_of :applicant_status, in: APPLICANT_STATUSES, allow_nil: true

  BAR_LICENSE_TYPES = %w{SCLPS_2_HR_TRAINING SCOTTISH_PERSONAL_LICENSE ENGLISH_PERSONAL_LICENSE SCREEN_SHOT_OF_SCLPS}.freeze
  validates_inclusion_of :bar_license_type, in: BAR_LICENSE_TYPES, allow_nil: true

  before_destroy prepend: true do |prospect|
    # Only allow new Prospects who have never worked an Event to be deleted
    if prospect.gigs.any? && !$FORCE_DESTROY
      throw :abort
    end
  end

  STATUSES.each do |s|
    scope s.downcase.pluralize.to_sym, -> { where(status: s) }
    define_method("#{s.downcase}?".to_sym) { self.status == s }
  end

  def self.last_months_applicants
    where(status: 'APPLICANT').where(created_at: Date.today.last_month.beginning_of_month...Date.today.beginning_of_month).count
  end

  def self.current_month_applicants
    where(status: 'APPLICANT').where(created_at: Time.current.beginning_of_month..Time.current).count
  end

  def self.active_people_last_year
    where.not(last_login: nil).where(last_login: 1.year.ago...Time.current).count
  end

  def name
    "#{last_name}, #{first_name}"
  end
  def show_name
    "#{first_name} #{last_name}"
  end
#   def contact_no
#    mobile_no.present? ? mobile_no : home_no
#   end
  def has_id?
    id_submitted? && id_sighted
  end
  def id_submitted?
    id_type && id_number && (id_type != 'Pass Visa' || visa_number) && (id_type != 'Work/Residency Visa' || share_code) && (visa_expiry.nil? || visa_expiry >= Date.today) && has_uploaded_id_scans?
  end
  def lacking_needed_share_code?
    id_type && 
    id_number && 
    (visa_expiry.nil? || visa_expiry >= Date.today) &&
    id_type != 'Pass Visa' &&
    has_uploaded_id_scans? &&
    share_code.blank? &&
    nationality.others?
  end
  def passport_sent?
    id_type && id_number && has_uploaded_id_scans?
  end
  def id_expired?
    id_type && id_sighted && visa_expiry && visa_expiry < Date.today
  end
  def has_uploaded_id_scans?
    scanned_ids.present?
  end
  def has_bank_details?
    bank_account_no.present? && bank_account_name.present? && bank_sort_code.present?
  end
  def has_tax_choice?
    tax_choice.present?
  end
  def agreed_to_terms?
    datetime_agreement.present?
  end
  def answered_mandatory_questions?
    questionnaire && questionnaire.answered_mandatory_questions?
  end
  def answered_latest_mandatory_questions?
    questionnaire && questionnaire.answered_latest_mandatory_questions?
  end
  def answered_whole_questions?
    questionnaire && questionnaire.answered_whole_mandatory_questions? && has_work_time? && has_skills_and_interests? && has_contact?
  end

  def v2_applications_done?
    questionnaire && questionnaire.v2_applications_done?
  end

  def v2_skills_done?
    questionnaire && questionnaire.skills != {}
  end

  def v2_tax_done?
    tax_choice != nil
  end

  def v2_bank_done?
    (bank_account_no != nil && bank_account_no != "") && (bank_sort_code != nil && bank_sort_code != "")
  end

  def v2_id_done?
    id_submitted?
  end

  def has_contact?
    questionnaire.contact_via_text == true ||
    questionnaire.contact_via_email == true ||
    questionnaire.contact_via_telephone == true||
    questionnaire.contact_via_whatsapp == true
  end
  def answered_some_questions?
    questionnaire && questionnaire.answered_some_questions?
  end
  def needs_to_update_questionnaire?
    !questionnaire || questionnaire.needs_to_update_questionnaire?
  end
  def has_personal_details?
    first_name.present? &&
    gender.present? &&
    (ni_number.present? || !applicant?) &&
    last_name.present? &&
    mobile_no.present? &&
    # home_no.present? &&
    address.present? &&
    # city.present? &&
    date_of_birth.present? &&
    email.present? &&
    post_code.present? &&
    nationality.present? &&
    kid_datetime.present? &&
    datetime_agreement.present?
  end
  def has_any_personal_details?
    gender.present? ||
    ni_number.present? ||
    address.present? ||
    nationality.present? ||
    photo.present? ||
    emergency_name.present? ||
    emergency_no.present?
  end
  def almost_has_personal_details?
    first_name.present? &&
    gender.present? &&
    ni_number.present? &&
    last_name.present? &&
    mobile_no.present? &&
    address.present? &&
    # city.present? &&
    date_of_birth.present? &&
    email.present? &&
    post_code.present? &&
    nationality.present?
  end
  def has_skills_and_interests?
    !questionnaire.has_sport_and_outdoor.nil? ||
    !questionnaire.has_bar_and_hospitality.nil? ||
    !questionnaire.has_festivals_and_concerts.nil? ||
    !questionnaire.has_merchandise_and_retail.nil? ||
    !questionnaire.has_promotional_and_street_marketing.nil? ||
    !questionnaire.has_reception_and_office_admin.nil?
  end
  def has_industrial_qualification?
    questionnaire.dbs_qualification == true ||
    questionnaire.food_health_level_two_qualification == true ||
    questionnaire.english_personal_licence_qualification == true ||
    questionnaire.scottish_personal_licence_qualification == true
  end
  def has_work_time?
    questionnaire.week_days_work == true ||
    questionnaire.weekends_work == true ||
    questionnaire.day_shifts_work == true ||
    questionnaire.evening_shifts_work == true
  end
  def has_some_non_registration_details?
    gender.present? ||
    ni_number.present? ||
    mobile_no.present? ||
    address.present?
    # city.present?
  end
  def has_contact_preferences?
    (prefers_skype_and_has_id? || prefers_facetime_and_has_id? || prefers_phone_and_has_number? || prefers_in_person.present?) &&
    (prefers_morning? || prefers_afternoon? || prefers_early_evening? || prefers_midweek? || prefers_weekend?)
  end
  def has_mandatory_profile_information?
    has_personal_details? &&
    # has_contact_preferences? &&
    photo.present? &&
    answered_mandatory_questions?
  end
  def has_photo?
    photo.present?
  end

  # has this person done everything they need to do on the website before they actually
  #   work an Event?
  def ready_to_go?
    has_uploaded_id_scans? && has_bank_details? && has_tax_choice? && agreed_to_terms? && has_mandatory_profile_information?
  end
  # If not, get a list of links for the things they still need to do
  def still_needed
    result = []
    result << "upload scanned images of your ID"                    unless has_uploaded_id_scans?
    result << "enter your bank account number (so we can pay you)"  unless has_bank_details?
    result << "help us determine the right tax code for you"        unless has_tax_choice?
    result << "agree to our Terms of Engagement"                    unless agreed_to_terms?
    result << "fill out all personal details"                       unless has_personal_details?
    result
  end

  PROSPECT_THUMBNAIL_SIZE = {width: 480, height: 640}

  def photo_url
    photo ? "/prospect_photo/#{self.id}" : "/assets/no-prospect-photo.png"
  end

  def age(reference_date = Time.now.utc.to_date)
    return nil unless date_of_birth
    dob = date_of_birth
    age = reference_date.year - dob.year
    if dob.month > reference_date.month || (dob.month == reference_date.month && dob.day > reference_date.day)
      age -= 1
    end
    age
  end

  # OPTIONAL VALIDATIONS
  # These methods must be called manually when you want to validate that
  #   the optional fields are present
  # (In some cases, we do want to create Prospect records without these fields)
  def validate_mandatory_office_fields
    validate_first_name_present
    validate_last_name_present
    validate_status_present
    validate_email_present
    validate_gender_present
    validate_phone_present
    if status == 'EXTERNAL'
      validate_client_present
      validate_dob_present
    else
      validate_post_code_present
      validate_dob_present
      validate_address_present
      validate_city_present
      validate_nationality
    end
    errors.full_messages.length == 0
  end
  def validate_id_expiry_present
    errors.add(:id_expiry, 'must be filled in') unless id_expiry.present?
  end
  def validate_first_name_present
    errors.add(:first_name, 'must be filled in') unless first_name.present?
  end
  def validate_last_name_present
    errors.add(:last_name, 'must be filled in') unless last_name.present?
  end
  def validate_status_present
    errors.add(:status, 'must be selected') unless status.present?
  end
  def validate_email_present
    errors.add(:email, 'must be filled in') unless email.present?
  end
  def validate_gender_present
    errors.add(:gender, 'must be selected') unless gender.present?
  end

  def validate_photo
    errors.add(:photo, 'must be uploaded.') unless photo.present?
  end

  def validate_dob_present
    errors.add(:date_of_birth, 'must be filled in') unless date_of_birth.present?
  end
  def validate_post_code_present
    errors.add(:post_code, 'must be filled in') unless post_code.present?
  end
  def validate_address_present
    errors.add(:address, 'must be filled in') unless address.present?
    # errors.add(:city, 'must be filled in') unless city.present?
  end
  def validate_phone_present
    errors.add(:mobile_no, 'must be filled in') unless mobile_no.present?
  end
  def validate_photo_present
    errors.add(:base, 'You must upload a photo') unless photo.present?
  end
  def validate_questions_completed
    errors.add(:base, 'You must answer all the questions') unless completed_questions?
  end
  def validate_bar_experience_present
    errors.add(:base, 'You must indicate your bar experience') unless bar_experience.present?
  end
  def validate_client_present
    errors.add(:base, 'Client must be selected for External Employees') unless client_id.present?
  end
  def validate_nationality
    errors.add(:nationality, 'must be filled in') unless nationality.present?
  end
  def validate_ni_number
    errors.add(:ni_number, 'must be filled in') unless ni_number.present?
  end
  def validate_city_present
    errors.add(:city, 'must be filled in') unless city.present?
  end
  def validate_preferred_contact_time
    errors.add(:base, 'You must enter your preferred contact time') unless prefers_morning.present? || prefers_afternoon.present? || prefers_early_evening.present? || prefers_midweek.present? || prefers_weekend.present?
  end
  def validate_prefers_facetime
    errors.add(:base, 'You must be enter your facetime email or number') if prefers_facetime.present? && !preferred_facetime.present?
  end
  def validate_prefers_skype
    errors.add(:base, 'You must enter your Skype ID') if prefers_skype.present? && !preferred_skype.present?
  end
  def validate_prefers_phone
    errors.add(:base, 'You must enter your preferred contact phone number') if prefers_phone.present? && !preferred_phone.present?
  end
  def validate_contact_preference
    errors.add(:base, 'You must enter your preferred contact method') unless (prefers_facetime.present? || prefers_skype.present? || prefers_phone.present? || prefers_in_person.present?)
  end
  def prefers_skype_and_has_id?
    prefers_skype.present? && preferred_skype.present?
  end
  def prefers_phone_and_has_number?
    prefers_phone.present? && preferred_phone.present?
  end
  def prefers_facetime_and_has_id?
    prefers_facetime.present? && preferred_facetime.present?
  end

  def payment_method
    bank_sort_code && bank_account_no && bank_account_name && id_sighted ? "Bank" : "Cheque"
  end

  def external_employee?
    status == 'EXTERNAL'
  end

  def current_employee?
    %w[EMPLOYEE EXTERNAL].include?(status)
  end

  def send_auto_emails?
    status != 'EXTERNAL'
  end

  def include_in_brightpay?
    status != 'EXTERNAL'
  end

  def allowTimeClockingAppLogin?
    current_employee?
  end

  ## Time Clocking App
  def ethics_meaning
    questionnaire.try(:ethics_meaning)
  end

  def customer_service_meaning
    questionnaire.try(:customer_service_meaning)
  end

  def average_rating
    rating = self.gigs.average(:rating)
    rating || self.rating
  end

  def gigs_count
    self.gigs.joins(:event).where("events.status = 'CLOSED'").count
  end

  def not_applicant
    status != 'APPLICANT' ? true : false
  end

  def is_interview_assigned
    interview.present?
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({ :methods => [:ethics_meaning, :customer_service_meaning, :average_rating, :gigs_count] }))
  end

end
