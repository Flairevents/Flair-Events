class ChangeTaxCodeFrom1000lTo1060lOnProspect < ActiveRecord::Migration
  def up
    Prospect.find_each do |p|
      if p.tax_code == '1000L'
        p.tax_code = '1060L'
        p.save
      end
    end
  end

  def down
  end
end
