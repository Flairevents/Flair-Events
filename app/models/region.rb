class Region < ApplicationRecord
  has_many :post_regions,    dependent: :restrict_with_error
  has_many :events,          dependent: :restrict_with_error
  has_many :prospects,       dependent: :restrict_with_error
  has_many :bulk_interviews, dependent: :restrict_with_error
end