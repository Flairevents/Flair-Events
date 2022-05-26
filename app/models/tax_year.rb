require 'office_zone_sync'

class TaxYear < ApplicationRecord
  include OfficeZoneSync

  has_many :tax_weeks, dependent: :restrict_with_error

  validates_presence_of :date_start, :date_end

  def tax_code_from_choice(choice)
    case(choice)
      when 'A' then tax_code_a
      when 'B' then tax_code_b
      when 'C' then tax_code_c
      else error("Unknown Tax Choice")
    end
  end

  def update_tax_year_2021
    tax_year = TaxYear.find(9)
    tax_year.update(
      tax_code_a: "1257L",
      tax_code_b: "1257L",
      tax_code_c: "BR",
    )
  end
end
