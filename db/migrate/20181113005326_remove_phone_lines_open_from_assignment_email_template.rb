class RemovePhoneLinesOpenFromAssignmentEmailTemplate < ActiveRecord::Migration[5.2]
  def change
    remove_column :assignment_email_templates, :phone_lines_open, :text
  end
end
