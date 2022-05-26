class UpdateChangeRequests < ActiveRecord::Migration[5.1]
  def up
    ChangeRequest.where(processed: true).destroy_all
    ChangeRequest.where(bank_sort_code: nil, bank_account_no: nil, bank_account_name: nil).destroy_all

    remove_column :change_requests, :address,            :string
    remove_column :change_requests, :address2,           :string 
    remove_column :change_requests, :city,               :string
    remove_column :change_requests, :post_code,          :string
    remove_column :change_requests, :email,              :string
    remove_column :change_requests, :home_no,            :string
    remove_column :change_requests, :mobile_no,          :string
    remove_column :change_requests, :emergency_no,       :string
    remove_column :change_requests, :emergency_name,     :string
    remove_column :change_requests, :ni_number,          :string
    remove_column :change_requests, :tax_choice,         :string
    remove_column :change_requests, :student_loan,       :string
    remove_column :change_requests, :date_tax_choice,    :date
    remove_column :change_requests, :date_of_birth,      :date
    remove_column :change_requests, :gender,             :string
    remove_column :change_requests, :preferred_phone,    :string
    remove_column :change_requests, :preferred_facetime, :string
    remove_column :change_requests, :preferred_skype,    :string
    remove_column :change_requests, :processed,          :boolean
    remove_column :change_requests, :officer_id,         :integer
  end
end
