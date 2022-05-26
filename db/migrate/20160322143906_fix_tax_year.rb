class FixTaxYear < ActiveRecord::Migration
  def up
    remove_index :tax_weeks, :tax_year
    remove_index :tax_weeks, [:status, :tax_year, :tax_week, :gig_id]
    remove_index :tax_weeks, [:status, :tax_year, :tax_week]
    TaxWeek.all.each do |tw|
      tw.tax_year = tw.tax_year - 1
      tw.save
    end
    add_index :tax_weeks, :tax_year
    add_index :tax_weeks, [:status, :tax_year, :tax_week, :gig_id]
    add_index :tax_weeks, [:status, :tax_year, :tax_week]

    remove_index :tax_week_details_histories, [:prospect_id, :tax_year]
    remove_index :tax_week_details_histories, name: 'index_tax_week_details_histories_on_prospect_tax_year_week'
    remove_index :tax_week_details_histories, [:tax_year, :tax_week]
    TaxWeekDetailsHistory.all.each do |twdh|
      twdh.tax_year = twdh.tax_year - 1
      twdh.save
    end
    add_index :tax_week_details_histories, [:prospect_id, :tax_year]
    add_index :tax_week_details_histories, [:prospect_id, :tax_year, :tax_week], unique: true, name: 'index_tax_week_details_histories_on_prospect_tax_year_week'
    add_index :tax_week_details_histories, [:tax_year, :tax_week]
  end
end
