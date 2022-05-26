class AdminLog < ActiveRecord::Migration[5.1]
  def change
    create_table :admin_log do |t|
      t.string :type
      t.json   :data
      t.timestamps
    end

    add_index :admin_log, :created_at
  end
end
