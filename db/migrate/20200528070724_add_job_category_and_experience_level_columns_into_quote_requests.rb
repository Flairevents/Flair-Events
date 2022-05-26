class AddJobCategoryAndExperienceLevelColumnsIntoQuoteRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :quote_requests, :experience, :string
    add_column :quote_requests, :job_category, :string
  end
end
