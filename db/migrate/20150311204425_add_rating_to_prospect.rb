class AddRatingToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :rating, :integer
  end
  def down
    remove_column :prospects, :rating
  end
end
