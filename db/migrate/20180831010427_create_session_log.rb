class CreateSessionLog < ActiveRecord::Migration[5.2]
  def change
    create_table :session_logs do |t|
      t.integer    :account_id, null: false
      t.string     :login_ip, null: false
      t.string     :login_ip_coordinates
      t.string     :login_ip_location
      t.datetime   :login_time, null: false
      t.datetime   :logout_time
      t.timestamps
    end
    add_index :session_logs, :account_id
  end
end
