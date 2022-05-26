class DetailsHistory < ApplicationRecord
  self.table_name = 'details_history'
  belongs_to :prospect

  validates_presence_of :column, :changed_by

  def self.tracked_columns
    [
      :address,
      :address2,
      :bank_account_name,
      :bank_account_no,
      :bank_sort_code,
      :city,
      :email,
      :emergency_no,
      :first_name,
      :home_no,
      :id_expiry,
      :id_number,
      :id_type,
      :last_name,
      :mobile_no,
      :post_code,
      :visa_expiry,
      :visa_indefinite,
      :visa_issue_date,
      :visa_number
    ]
  end
end