class PayWeekDetailsHistory < ApplicationRecord
  belongs_to :tax_week
  belongs_to :prospect

  def copy_from_prospect(prospect)
    (self.attribute_names - %w(id prospect_id tax_week_id nationality created_at updated_at)).each do |attr|
      value =  prospect.send(attr.to_sym)

      ##### address2 is a bit annoying. If set in the staff zone as empty, it is ''
      ##### if set in the office zone as empty it is nil
      ##### force it to always be ''
      value = '' if (attr == 'address2' && value.nil?)

      self[attr] = value
    end
    self.nationality = prospect.nationality.try(:name)
  end
end