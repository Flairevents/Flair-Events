class AddCountryBhutan < ActiveRecord::Migration[5.2]
  def change
    Country.create!(name: 'Bhutan')
  end
end
