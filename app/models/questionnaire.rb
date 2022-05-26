require 'office_zone_sync'

class Questionnaire < ApplicationRecord
  include OfficeZoneSync

  belongs_to :prospect
  after_initialize :set_default_version
  after_save :update_version

  validates_presence_of :prospect_id
  validates_presence_of :version
  serialize :skills, Hash

  def answered_mandatory_questions?
    mandatory_v2 << :criminal_conviction_details if has_criminal_convictions

    mandatory = case self.version
      when 1
        mandatory_v1
      when 2
        mandatory_v2
      else
        raise "Need to add support for questionnaire v#{self.version}"
    end
    mandatory.select {|a| answered?(a) }.length == mandatory.length
  end

  def answered_latest_mandatory_questions?
    mandatory_latest.select {|a| answered?(a) }.length == mandatory_latest.length
  end

  def answered_whole_mandatory_questions?
    mandatory_whole.select {|a| answered?(a) }.length == mandatory_whole.length
  end

  def v2_applications_done?
    inputs = [
      :favorite_film,
      :best_place,
      :job1_date_start,
      :job1_type,
      :job1_position,
      :job1_company,
      :job1_description,
      :customer_service_why_interested,
      :has_criminal_convictions
    ]

    inputs.each do |input|
      if self[input] == nil || self[input] == ""
        return false
      end
    end

    return true 
  end

  def needs_to_update_questionnaire?
    mandatory_latest.select {|a| answered?(a) }.length != mandatory_latest.length
  end

  def answered_some_questions?
    # Unfortunately, we can't detect if some answers were answered, since they are just checkboxes. So ignore these when determining if some questions were answered if they were false
    indeterminate_questions = [:enjoy_working_on_team, :interested_in_bar, :interested_in_marshal, :retail_experience, :team_leader_experience, :promotions_experience]
    (question_fields - indeterminate_questions).select {|a| answered?(a) }.length > 0 || indeterminate_questions.select {|a| a == true }.length > 0
  end

  def boolean_question_fields
    Questionnaire.attribute_names.select {|a| Questionnaire.columns_hash[a].type == :boolean}
  end

  def question_fields
    Questionnaire.attribute_names.map {|a| a.to_sym} - [:id, :prospect_id, :created_at, :updated_at, :version]
  end

  private
  def mandatory_v1
    [
      :favorite_film,
      :best_place
    ]
  end

  def mandatory_v2
    mandatory_v1 + [
      :job1_date_start,
      :job1_type,
      :job1_position,
      :job1_company,
      :job1_description,
      :customer_service_why_interested,
      :customer_service_meaning,
      :ethics_meaning,
      :has_criminal_convictions
    ]
  end

  def whole_mandatory_questions
    mandatory_v1 + [
        :job1_date_start,
        :job1_type,
        :job1_position,
        :job1_company,
        :job1_description,
        :customer_service_why_interested,
        :customer_service_meaning,
        :ethics_meaning,
        :has_criminal_convictions
    ]
  end

  def mandatory_whole
    whole_mandatory_questions
  end

  def mandatory_latest
    mandatory_v2
  end

  def answered?(answer)
    self[answer] != nil && self[answer] != ''
  end

  DEFAULT_VERSION = 2
  def update_version
    if answered_latest_mandatory_questions?
      self.version = DEFAULT_VERSION
    end
  end
  def set_default_version
    self.version ||= DEFAULT_VERSION
  end
end
