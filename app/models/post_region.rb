class PostRegion < ApplicationRecord
  belongs_to :region
  has_many   :post_areas
end