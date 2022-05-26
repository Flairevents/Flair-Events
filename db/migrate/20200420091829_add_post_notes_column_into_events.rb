class AddPostNotesColumnIntoEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :post_notes, :text
  end
end
