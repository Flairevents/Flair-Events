class AddSendScheduledToWorkAutoEmailToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :send_scheduled_to_work_auto_email, :boolean, default: true, null: false
  end
end
