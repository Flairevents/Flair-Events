class ChangeTaxCodeFrom1100LTo1050LOnProspect < ActiveRecord::Migration[4.2]
  def up
    Prospect.find_each do |p|
      if p.tax_code == '1100L'
        p.tax_code = '1050L'
        p.save
      end
    end
  end

  def down
  end
end
