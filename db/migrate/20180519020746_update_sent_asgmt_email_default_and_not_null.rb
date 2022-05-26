class UpdateSentAsgmtEmailDefaultAndNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column :gig_tax_weeks, :sent_asgmt_email_info,    :boolean, default: false, null: false
    change_column :gig_tax_weeks, :sent_asgmt_email_confirm, :boolean, default: false, null: false 
    change_column :gig_tax_weeks, :sent_asgmt_email_part,    :boolean, default: false, null: false
    change_column :gig_tax_weeks, :sent_asgmt_email_full,    :boolean, default: false, null: false
  end
end
