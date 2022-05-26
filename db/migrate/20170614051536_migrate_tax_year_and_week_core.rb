class MigrateTaxYearAndWeekCore < ActiveRecord::Migration[4.2]
  def up
    puts "-- Porting Pay Weeks"
    PayWeek.connection.schema_cache.clear!
    PayWeek.reset_column_information
    PayWeek.all.each do |pw|
      portTaxWeek(pw)
    end
    puts "-- Porting Pay Week Details Histories"
    PayWeekDetailsHistory.connection.schema_cache.clear!
    PayWeekDetailsHistory.reset_column_information
    PayWeekDetailsHistory.all.each do |pwdh|
      portTaxWeek(pwdh)
    end
    puts "-- Porting Invoices"
    Invoice.connection.schema_cache.clear!
    Invoice.reset_column_information
    Invoice.all.each do |i|
      portTaxWeek(i)
    end
  end
  def portTaxWeek(obj)
    date = Date.new(obj.tax_year, 9, 1)
    ty = TaxYear.where('date_start <= ? AND ? <= date_end', date, date).first
    tw = TaxWeek.where(tax_year_id: ty.id, week: obj.tax_week2).first
    raise "Can't find tax_year and tax_week for #{obj.inspect}" unless ty && tw
    obj.tax_week3_id = tw.id
    #puts "obj: #{obj.inspect}"
    obj.save!
  end
  def down
    puts "-- Reverting Pay Weeks"
    PayWeek.all.each do |pw|
      revertTaxWeek(pwj)
    end
    puts "-- Reverting Pay Week Details Histories"
    PayWeekDetailsHistory.all.each do |pwdh|
      revertTaxWeek(pwdh)
    end
    puts "-- Reverting Invoices"
    Invoice.all.each do |i|
      revertTaxWeek(i)
    end
  end
  def revertTaxWeek(obj)
    tw = TaxWeek.where(id: obj.tax_week_id).first
    obj.tax_week = tw.week
    obj.tax_year = tw.tax_year.date_start.year
    #puts "#{tw.inspect} to #{obj.tax_year} #{obj.tax_week}"
    obj.save!
  end
end
