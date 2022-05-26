class EventCategory < ApplicationRecord
  has_many :events, foreign_key: :category_id

  def self.new_categories
    old_categories_ids = [1,2,3,4,5,6]

    self.where.not(id: old_categories_ids)
  end
end