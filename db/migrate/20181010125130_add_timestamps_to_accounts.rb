class AddTimestampsToAccounts < ActiveRecord::Migration[5.2]
  def change
    # this is necessary to load account records into the Office Zone
    add_timestamps(:accounts, default: DateTime.now)
  end
end
