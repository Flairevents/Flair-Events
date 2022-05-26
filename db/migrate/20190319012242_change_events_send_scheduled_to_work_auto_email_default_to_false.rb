class ChangeEventsSendScheduledToWorkAutoEmailDefaultToFalse < ActiveRecord::Migration[5.2]
  def change
    change_column_default :events, :send_scheduled_to_work_auto_email, false
  end
end
