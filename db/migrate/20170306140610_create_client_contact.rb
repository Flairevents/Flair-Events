class CreateClientContact < ActiveRecord::Migration
  def change
    add_column :bookings, :client_contact_id, :integer
    add_column :clients, :primary_client_contact_id, :integer
    create_table :client_contacts do |t|
      t.integer :client_id
      t.string  :first_name
      t.string  :last_name
      t.string  :email
      t.string  :mobile_no
      t.boolean :active, default: true, null: false
      t.timestamps null: false
    end
  end
end
