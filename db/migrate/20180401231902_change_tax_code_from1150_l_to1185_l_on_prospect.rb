class ChangeTaxCodeFrom1150LTo1185LOnProspect < ActiveRecord::Migration[5.1]
    def up
    Prospect.find_each do |p|
      if p.tax_code == '1150L'
        p.tax_code = '1185L'
        p.save
      end
    end
  end

  def down
    Prospect.find_each do |p|
      if p.tax_code == '1185L'
        p.tax_code = '1150L'
        p.save
      end
    end
  end
end
