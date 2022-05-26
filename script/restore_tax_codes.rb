require 'csv'
all_info = CSV.read('dumped_tax_codes.csv')

all_info.each do |info|
  if prospect = Prospect.find_by_id(info[0])
    prospect.tax_code = info[1]                    if !prospect.tax_code        && info[1]
    prospect.tax_choice = info[2]                  if !prospect.tax_choice      && info[2]
    prospect.date_tax_choice = Date.parse(info[3]) if !prospect.date_tax_choice && info[3]
    prospect.save
  end
end
