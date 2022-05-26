require 'brightpay'
include Brightpay

class GenerateTaxWeeks < ActiveRecord::Migration[4.2]
  def up 
    ###### Calculate TaxYears
    date_start = Date.new(2013,4,6)
    date_end = Date.new(2018,3,25)
    tax_years = {}
    date_start.upto(date_end) do |date|
      twh = date_to_taxweek(date)
      tax_years[twh[:year]] ||= {}
      tax_years[twh[:year]][:date_start] ||= date
      tax_years[twh[:year]][:date_start] = [tax_years[twh[:year]][:date_start], date].min
      tax_years[twh[:year]][:date_end] ||= date
      tax_years[twh[:year]][:date_end] = [tax_years[twh[:year]][:date_end], date].max
    end
    ##### Create TaxYears
    tax_years.each do |year,tyh|
      ty = TaxYear.new
      ty.date_start = tyh[:date_start]
      ty.date_end = tyh[:date_end]
      ty.save
    end

    ##### Calculate TaxWeeks
    TaxYear.all.each do |ty|
      ty.date_start.upto(ty.date_end) do |date|
        twh = date_to_taxweek(date) 
        if TaxWeek.where(tax_year_id: ty.id, week: twh[:week]).length < 1
          tw = TaxWeek.new
          tw.date_start = twh[:start]
          tw.date_end = twh[:end]
          tw.week = twh[:week]
          tw.tax_year_id = ty.id 
          tw.save
        end
      end
    end
  end
  def down
    TaxYear.destroy_all
    TaxWeek.destroy_all
  end
end
