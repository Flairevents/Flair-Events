class CreateCountryTogo < ActiveRecord::Migration
  def up
    Country.create(name: 'Togo')
  end
  def down
    Country.where(name: 'Togo').first.destroy
  end
end
