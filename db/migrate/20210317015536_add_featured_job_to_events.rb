class AddFeaturedJobToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :featured_job, :integer
  end
end
