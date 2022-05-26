class CreateCountryJordan < ActiveRecord::Migration
  def up
    Country.create(name: 'Jordan')
  end
  def down
    Country.where(name: 'Jordan').first.destroy
  end
end
