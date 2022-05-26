class AddMarketResearchToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :market_research, :string
  end
end
