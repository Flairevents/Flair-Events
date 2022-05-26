class CreateAccountsForProspectsWithNoAccounts < ActiveRecord::Migration[5.1]
  def up
    Prospect.select {|p| !(p.account)}.each do |p|
      Account.create(user_id: p.id, user_type: 'Prospect')
    end
  end
end
