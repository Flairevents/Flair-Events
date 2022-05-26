class UnsubscribeToken < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :unsubscribe_token, :string
    add_index :accounts, :unsubscribe_token

    Account.all.each do |account|
      account.unsubscribe_token = account.generate_unique_token(:unsubscribe_token)
      account.save!
    end
  end
end
