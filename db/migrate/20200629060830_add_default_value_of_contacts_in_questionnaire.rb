class AddDefaultValueOfContactsInQuestionnaire < ActiveRecord::Migration[5.2]
  def up
    change_column :questionnaires, :contact_via_email, :boolean, :default => true
    change_column :questionnaires, :contact_via_telephone, :boolean, :default => true
    change_column :questionnaires, :contact_via_text, :boolean, :default => true
    change_column :questionnaires, :contact_via_whatsapp, :boolean, :default => true

    Questionnaire.where(contact_via_email: nil ).update_all(contact_via_email: true )

    Questionnaire.where(contact_via_telephone: nil ).update_all(contact_via_telephone: true )

    Questionnaire.where(contact_via_text: nil ).update_all(contact_via_text: true )

    Questionnaire.where(contact_via_whatsapp: nil ).update_all(contact_via_whatsapp: true )
  end

  def down
    change_column :questionnaires, :contact_via_email, :boolean, :default => nil
    change_column :questionnaires, :contact_via_telephone, :boolean, :default => nil
    change_column :questionnaires, :contact_via_text, :boolean, :default => nil
    change_column :questionnaires, :contact_via_whatsapp, :boolean, :default => nil
  end
end
