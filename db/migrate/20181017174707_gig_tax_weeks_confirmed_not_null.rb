class GigTaxWeeksConfirmedNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null    :gig_tax_weeks, :confirmed, false
    change_column_default :gig_tax_weeks, :confirmed, false
  end
end
