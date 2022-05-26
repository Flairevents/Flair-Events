class AddRatingColumnsIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :flair_image, :float
    add_column :prospects, :experienced, :float
    add_column :prospects, :chatty, :float
    add_column :prospects, :confident, :float
    add_column :prospects, :energy, :float

    add_column :prospects, :big_teams, :string
    add_column :prospects, :all_teams, :string
    add_column :prospects, :bespoke, :string
  end
end
