class AddCountryOman < ActiveRecord::Migration[5.2]
  def change
    Country.create!(name: 'Oman')
  end
end
