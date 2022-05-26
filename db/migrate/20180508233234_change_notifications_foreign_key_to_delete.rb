class ChangeNotificationsForeignKeyToDelete < ActiveRecord::Migration[5.1]
  def change
    execute "ALTER TABLE notifications DROP CONSTRAINT notifications_recipient_fkey"
    execute "ALTER TABLE notifications ADD FOREIGN KEY (recipient) REFERENCES accounts (id) MATCH FULL ON DELETE cascade"
  end
end
