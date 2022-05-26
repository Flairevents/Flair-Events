class AddFirstNameLastNameIntoQuoteRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :quote_requests, :first_name, :string
    add_column :quote_requests, :last_name, :string
  end
end
