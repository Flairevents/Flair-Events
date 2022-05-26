class ChangeIntegerToFloat < ActiveRecord::Migration[5.2]
  def self.up
    change_column :prospects, :rating, 'float USING CAST(rating AS integer)'
  end

  def self.down
    change_column :prospects, :rating, 'integer USING CAST(rating AS float)'
  end
end
