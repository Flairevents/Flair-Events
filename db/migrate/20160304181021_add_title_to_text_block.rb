class AddTitleToTextBlock < ActiveRecord::Migration
  def change
    add_column :text_blocks, :title, :string
  end
end
