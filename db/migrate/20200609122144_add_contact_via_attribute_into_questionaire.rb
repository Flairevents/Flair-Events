class AddContactViaAttributeIntoQuestionaire < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :contact_via, :string
  end
end
