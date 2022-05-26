class AddGigsCountToEvents < ActiveRecord::Migration

  def self.up

    add_column :events, :gigs_count, :integer, :null => false, :default => 0

  end

  def self.down

    remove_column :events, :gigs_count

  end

end
