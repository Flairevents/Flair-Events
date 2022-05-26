class AddFullnessAndShowInPublicToEvent < ActiveRecord::Migration
  def change
    add_column :events, :fullness, :string
    add_column :events, :show_in_public, :boolean, allow_nil: false, default: true
  end
end
