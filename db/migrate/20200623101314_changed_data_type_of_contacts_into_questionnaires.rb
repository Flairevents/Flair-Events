class ChangedDataTypeOfContactsIntoQuestionnaires < ActiveRecord::Migration[5.2]
  def up
    change_column :questionnaires, :contact_via_whatsapp, 'boolean USING CAST(contact_via_whatsapp AS boolean)'
    change_column :questionnaires, :contact_via_telephone, 'boolean USING CAST(contact_via_telephone AS boolean)'
    change_column :questionnaires, :contact_via_email, 'boolean USING CAST(contact_via_email AS boolean)'
    change_column :questionnaires, :contact_via_text, 'boolean USING CAST(contact_via_text AS boolean)'
  end

  def down
    change_column :questionnaires, :contact_via_whatsapp, :string
    Questionnaire.where(contact_via_whatsapp: 'false').update(contact_via_whatsapp: '0')
    Questionnaire.where(contact_via_whatsapp: 'true').update(contact_via_whatsapp: '1')

    change_column :questionnaires, :contact_via_telephone, :string
    Questionnaire.where(contact_via_telephone: 'false').update(contact_via_telephone: '0')
    Questionnaire.where(contact_via_telephone: 'true').update(contact_via_telephone: '1')

    change_column :questionnaires, :contact_via_email, :string
    Questionnaire.where(contact_via_email: 'false').update(contact_via_email: '0')
    Questionnaire.where(contact_via_email: 'true').update(contact_via_email: '1')

    change_column :questionnaires, :contact_via_text, :string
    Questionnaire.where(contact_via_text: 'false').update(contact_via_text: '0')
    Questionnaire.where(contact_via_text: 'true').update(contact_via_text: '1')
  end
end
