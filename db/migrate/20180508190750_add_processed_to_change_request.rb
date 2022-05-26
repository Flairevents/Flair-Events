class AddProcessedToChangeRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :change_requests, :processed, :boolean, null: false, default: false
  end
end
