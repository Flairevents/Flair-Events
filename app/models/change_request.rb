class ChangeRequest < ApplicationRecord
  belongs_to :prospect

  # the ChangeRequest fields should be subject to the same validation
  #   as the Prospect fields which they are written into if the request is accepted!
  validates_format_of :bank_account_name, without: /[^A-Z0-9&.\/ -]/, allow_nil: true, message: 'can only contain letters, numbers, spaces, or any of the following characters: &, ., /, or -'
  validates_length_of :bank_sort_code, is: 6, allow_nil: true
  validates_length_of :bank_account_no, is: 8, allow_nil: true

  # Make data validation messages appear in a more natural, grammatical way
  def self.human_attribute_name(attribute,options={})
    {bank_account_no: 'Bank Account Number',
     emergency_no: 'Emergency Number'}[attribute] || super
  end

  def content
    s = "For: #{prospect.first_name} #{prospect.last_name}\n"
    s << "New Bank Sort Code: #{bank_sort_code}\n"    if bank_sort_code.present?
    s << "New Bank Acct No: #{bank_account_no}\n"     if bank_account_no.present?
    s << "New Bank Acct Name: #{bank_account_name}\n" if bank_account_name.present?
    s
  end

  def self.fields
    [:bank_sort_code, :bank_account_no, :bank_account_name]
  end

  def empty?
    ChangeRequest.fields.none? { |k| self[k].present? }
  end

  def save
    if empty?
      destroy unless new_record?
      true
    else
      super
    end
  end
end
