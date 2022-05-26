##### Compare our internal records (up to pay week 12 of this tax year)

require 'csv'

tax_week = TaxWeek.where(tax_year_id: 6, week: 12).first
tax_week_ids = TaxWeek.where("tax_year_id = ? AND date_start <= ?", tax_week.tax_year_id, tax_week.date_start).pluck(:id)

removed_ids = []
added_ids = []
PayrollActivity.joins(:tax_week).where(tax_week_id: tax_week_ids).order('tax_weeks.date_start asc').group_by(&:prospect).each do |prospect, payroll_activities|
  case payroll_activities.last.action
  when 'REMOVED'
    removed_ids << prospect.id
  when 'ADDED'
    added_ids << prospect.id  
  else
    raise "Unknown Action! Oh No!!!"
  end
end

brightpay_ids = []
brightpay_csv_path = File.join('/', 'Users', 'szaboale', 'Development', 'Flair', 'flair', 'script', 'brightpay_week12.csv')
CSV.foreach(brightpay_csv_path) do |row|
  brightpay_ids << row[2].to_i
end

prospect_ids_to_remove_from_brightpay = removed_ids & brightpay_ids

prospect_ids_in_brightpay_not_in_our_records = brightpay_ids - removed_ids - added_ids

prospect_ids_that_should_be_in_brightpay = added_ids - brightpay_ids

CSV.open('leavers.csv', 'wb') do |csv|
  prospect_ids_to_remove_from_brightpay.map {|id| Prospect.find(id)}.sort_by {|p| "#{p.last_name} #{p.first_name}"}.each do |prospect|
    csv << [prospect.last_name, prospect.first_name, prospect.id, prospect.date_of_birth]
  end
end
   
CSV.open('unknown.csv', 'wb') do |csv|
  prospect_ids_in_brightpay_not_in_our_records.each do |id|
    prospect = Prospect.find(id)
    csv << [prospect.last_name, prospect.first_name, prospect.id, prospect.date_of_birth]
  end
end

CSV.open('should_be_in_brightpay.csv', 'wb') do |csv|
  prospect_ids_that_should_be_in_brightpay.each do |id|
    prospect = Prospect.find(id)
    csv << [prospect.last_name, prospect.first_name, prospect.id, prospect.date_of_birth]
  end
end

