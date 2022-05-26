class MarketingEmail < ActiveRecord::Migration[5.1]
  def change
    # In the future, we may send e-mail to Prospects informing them about upcoming events
    # Remember if they have specifically said they do not want those e-mails
    add_column :prospects, :send_marketing_email, :boolean, default: true, null: false
  end
end
