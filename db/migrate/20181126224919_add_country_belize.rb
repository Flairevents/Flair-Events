class AddCountryBelize < ActiveRecord::Migration[5.2]
  def change
    Country.create(name: 'Belize')
  end
end
