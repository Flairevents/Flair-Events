class CreateGigTaxWeeks < ActiveRecord::Migration[5.1]
  def change
    create_table :gig_tax_weeks do |t|
      t.belongs_to :gig, index: true
      t.belongs_to :tax_week, index: true
      t.boolean :sent_asgmt_email_info
      t.boolean :sent_asgmt_email_confirm
      t.boolean :sent_asgmt_email_part
      t.boolean :sent_asgmt_email_full
      t.timestamps null: false
    end
  end
end
