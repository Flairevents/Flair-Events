class CreateQuoteRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :quote_requests do |t|
      t.string :name
      t.string :company_name
      t.string :telephone
      t.string :email
      t.string :contract_name
      t.string :location
      t.string :post_code
      t.datetime :start_date
      t.datetime :finish_date
      t.string :job_position
      t.string :full_range
      t.string :number_of_people
      t.string :wage_rates
      t.text :other_facts

      t.timestamps
    end
  end
end
