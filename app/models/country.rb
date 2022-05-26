class Country < ApplicationRecord
  EUROPEAN = ['Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czech Republic',
     'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary',
     'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta',
     'Netherlands', 'Norway', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia',
     'Spain', 'Sweden', 'United Kingdom'].freeze
  IRELAND = 'Ireland'
  UNITED_KINGDOM = 'United Kingdom'

  scope :others, -> { where.not(name: [UNITED_KINGDOM, IRELAND]) }
  scope :uk_roi, -> { where(name: [UNITED_KINGDOM, IRELAND]) }

  def uk?
    name == UNITED_KINGDOM
  end

  def ireland?
    name == IRELAND
  end

  def others?
    !uk? && !ireland?
  end

  def eu?
    EUROPEAN.include?(self.name)
  end
end