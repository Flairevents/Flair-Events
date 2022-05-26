class AddContactsAttributesInQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :contact_via_email, :string
    add_column :questionnaires, :contact_via_telephone, :string
    add_column :questionnaires, :contact_via_text, :string
    add_column :questionnaires, :contact_via_whatsapp, :string
  end
end
