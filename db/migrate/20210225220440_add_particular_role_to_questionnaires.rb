class AddParticularRoleToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :particular_role, :string, default: nil
  end
end
