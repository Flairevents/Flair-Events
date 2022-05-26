class AddConfirmationToAssignmentEmailTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :assignment_email_templates, :confirmation, :text
  end
end
