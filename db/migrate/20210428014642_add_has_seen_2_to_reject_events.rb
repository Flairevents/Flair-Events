class AddHasSeen2ToRejectEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :reject_events, :has_seen_2, :boolean, default: false
  end
end
