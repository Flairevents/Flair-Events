class AddHistoryTrToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :history_tr, :text
    reversible do |change|
      change.up do
        Event.all.each { |e| e.save }
      end
    end
  end
end
