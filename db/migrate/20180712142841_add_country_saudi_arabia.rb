class AddCountrySaudiArabia < ActiveRecord::Migration[5.1]
  def change
    Country.create(name: 'Saudi Arabia')
  end
end
