class ChangeTaxCodeFrom1060LTo1100LOnProspect < ActiveRecord::Migration
  def up
    Prospect.find_each do |p|
      if p.tax_code == '1060L'
        p.tax_code = '1100L'
        p.save
      end
    end
  end

  def down
  end
end
