class CreateCountryFiji < ActiveRecord::Migration
  def up
    Country.create(name: 'Fiji')
  end
  def down
    Country.where(name: 'Fiji').first.destroy
  end
end
