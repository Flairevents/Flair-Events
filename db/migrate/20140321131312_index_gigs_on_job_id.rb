class IndexGigsOnJobId < ActiveRecord::Migration
  def up
    add_index :gigs, :job_id
  end

  def down
    remove_index :gigs, :job_id
  end
end
