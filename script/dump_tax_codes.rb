require 'csv'

tax_info = {}

Prospect.where('tax_code IS NOT NULL').each do |prospect|
  tax_info[prospect.id] ||= {}
  tax_info[prospect.id][:tax_code] = prospect.tax_code
end

Prospect.where('tax_choice IS NOT NULL').each do |prospect|
  tax_info[prospect.id] ||= {}
  tax_info[prospect.id][:tax_choice] = prospect.tax_choice
end

Prospect.where('date_tax_choice IS NOT NULL').each do |prospect|
  tax_info[prospect.id] ||= {}
  tax_info[prospect.id][:date_tax_choice] = prospect.date_tax_choice.to_s
end

CSV.open('dumped_tax_codes.csv', 'wb') do |csv|
  tax_info.keys.sort.each do |id|
    csv << [id, tax_info[id][:tax_code], tax_info[id][:tax_choice], tax_info[id][:date_tax_choice]]
  end
end

nil
