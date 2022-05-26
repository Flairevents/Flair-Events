class CreateCountrySaintLucia < ActiveRecord::Migration
  def up
    Country.create(name: 'Saint Lucia')
  end
  def down
    Country.where(name: 'Saint Lucia').first.destroy
  end
end
