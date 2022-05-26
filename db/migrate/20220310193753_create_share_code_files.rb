class CreateShareCodeFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :share_code_files do |t|
      t.string :path, null: false, default: false
      t.references :prospect, foreign_key: true

      t.timestamps
    end
  end
end
