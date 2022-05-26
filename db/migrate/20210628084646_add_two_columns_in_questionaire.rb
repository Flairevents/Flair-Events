class AddTwoColumnsInQuestionaire < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :recommended_you, :string
    add_column :questionnaires, :friends_connection, :string
  end
end
