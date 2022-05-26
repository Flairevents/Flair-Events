class AddTermsAndSafetyColumnsToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :terms_date_sent,          :date
    add_column :clients, :terms_date_received,      :date
    add_column :clients, :terms_client_contact_id,  :integer
    add_column :clients, :safety_date_sent,         :date
    add_column :clients, :safety_date_received,     :date
    add_column :clients, :safety_client_contact_id, :integer
  end
end
