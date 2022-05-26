class AddIdExpiryToProspect < ActiveRecord::Migration[5.1]
  def change
    add_column :prospects, :id_expiry, :date
  end
end
