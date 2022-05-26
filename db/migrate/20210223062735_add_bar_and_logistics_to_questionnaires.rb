class AddBarAndLogisticsToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :has_bar, :string, default: nil
    add_column :questionnaires, :has_logistics, :string, default: nil
  end
end
