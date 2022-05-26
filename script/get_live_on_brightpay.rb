require 'csv'

added_ids= []
removed_ids = []
tax_year = TaxYear.where("date_start <= ? AND ? <= date_end", Time.now, Time.now).first
tax_week_ids = TaxWeek.where(tax_year: tax_year).pluck(:id)
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

[{file_name: 'leavers.csv', ids: removed_ids}, {file_name: 'still_here.csv', ids: added_ids}].each do |info|
  CSV.open(info[:file_name], 'wb') do |csv|
    csv << ["Last Name", "First Name", "ID", "Date of Birth"]
    info[:ids].map {|id| Prospect.find(id)}.sort_by {|p| "#{p.last_name} #{p.first_name}"}.each do |prospect|
      csv << [prospect.last_name, prospect.first_name, prospect.id, prospect.date_of_birth]
    end
  end
end
