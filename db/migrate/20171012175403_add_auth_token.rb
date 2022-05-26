class AddAuthToken < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :authentication_token, :string
    add_index :accounts, :authentication_token

    ##### Schema is getting messed up somehow, and authentication_token ends up as nil if you don't reset it
    Account.connection.schema_cache.clear!
    Account.reset_column_information
    Account.all.each do |account|
      account.authentication_token = account.generate_unique_token(:authentication_token)
      account.save!
    end
  end
end
