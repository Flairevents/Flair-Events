class RenameAdminLogToAdminLogEntries < ActiveRecord::Migration[5.2]
  def change
    rename_table :admin_log, :admin_log_entries
  end
end
