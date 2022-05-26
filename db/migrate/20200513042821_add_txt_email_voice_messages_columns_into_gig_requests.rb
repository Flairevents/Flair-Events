class AddTxtEmailVoiceMessagesColumnsIntoGigRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :gig_requests, :left_voice_message, :boolean, null: false, default: false
    add_column :gig_requests, :email_status, :boolean, null: false, default: false
    add_column :gig_requests, :texted, :boolean, null: false, default: false
  end
end
