class CreateCountryMaltaAndLebanon < ActiveRecord::Migration[4.2]
  def change
   Country.create(name: 'Malta')
   Country.create(name: 'Lebanon')
  end
end
