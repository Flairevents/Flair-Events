class DropAccountSessionsTable < ActiveRecord::Migration[5.1]
  def change
  	# AccountSession was added as a way to track when each user logged in and out
  	# After several years in production, that feature has never been used
  	# So we are removing it to simplify things
  	drop_table :account_sessions
  end
end
