class AddWorkingPatternIntoQuoteRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :quote_requests, :working_pattern, :string
  end
end
