class AddClientTables < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.boolean :active, null: false, default: true
      t.string  :name
      t.string  :address
      t.string  :phone_no
      t.string  :primary_contact_name
      t.string  :primary_contact_mobile_no
      t.text    :notes
      t.timestamps null: false
    end

    #An event may have more than one client, so we use a joins table
    create_table :event_clients do |t|
      t.belongs_to :event, index: true
      t.belongs_to :client, index: true
      t.timestamps null: false
    end
  end
end
