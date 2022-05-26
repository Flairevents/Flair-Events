class CreateCountryAzerbaijan < ActiveRecord::Migration
  def up
    Country.create(name: 'Azerbaijan')
  end
  def down
    Country.where(name: 'Azerbaijan').first.destroy
  end
end
