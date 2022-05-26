class CreateTaxWeekDetailsHistory < ActiveRecord::Migration
  def up
    create_table :tax_week_details_histories do |t|
      t.integer :prospect_id, null: false
      t.integer :tax_year, null: false
      t.integer :tax_week, null:false
      t.string  :gender
      t.string  :last_name
      t.string  :first_name
      t.string  :date_of_birth
      t.string  :ni_number
      t.string  :address
      t.string  :address2
      t.string  :city
      t.string  :country
      t.string  :post_code
      t.string  :tax_code
      t.string  :student_loan
      t.string  :tax_choice
      t.string  :bank_account_no
      t.string  :bank_sort_code
      t.string  :bank_account_name
      t.string  :email
      t.string  :date_start
      t.string  :nationality
      t.string  :visa_number
      t.string  :payment_method
    end
    add_index :tax_week_details_histories, :prospect_id
    add_index :tax_week_details_histories, [:prospect_id, :tax_year]
    add_index :tax_week_details_histories, [:prospect_id, :tax_year, :tax_week], unique: true, name: 'index_tax_week_details_histories_on_prospect_tax_year_week'
    add_index :tax_week_details_histories, [:tax_year, :tax_week]
  end

  def down
    drop_table :tax_week_details_histories
  end
end
