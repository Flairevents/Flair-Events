class RenameCorporateToHospitalityInEventCategory < ActiveRecord::Migration
  def up
    if category = EventCategory.where(name: 'Corporate').first
      category.name = 'Hospitality'
      category.save
    end
  end
  def down
    if category = EventCategory.where(name: 'Hospitality').first
      category.name = 'Corporate'
      category.save
    end
  end
end
