class AddDateOpenedToEvents < ActiveRecord::Migration
  def change
    add_column :events, :date_opened, :date
  end
end
