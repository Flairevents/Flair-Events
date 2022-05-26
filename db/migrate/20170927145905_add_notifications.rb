class AddNotifications < ActiveRecord::Migration[5.1]
  def change
    # This is for batching up messages which we want to send to Prospects, etc.
    #   and then sending out a single message rather than spamming them with many
    create_table :notifications do |t|
      t.string  :type,      null: false
      t.integer :recipient, null: false # link to Account
      t.json    :data
      t.boolean :sent,      null: false, default: false
      t.timestamps
    end

    execute "ALTER TABLE notifications ADD FOREIGN KEY (recipient) REFERENCES accounts (id) MATCH FULL"

    add_index :notifications, [:sent, :created_at]
  end
end
