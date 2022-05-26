class AddMultipleTagsToEvents < ActiveRecord::Migration[5.1]
  def up
    create_table :gig_tags do |t|
      t.integer :gig_id
      t.integer :tag_id
      t.timestamps
    end
    add_index :gig_tags, :updated_at
    Gig.all.each do |gig|
      if gig.tag_id
        gig_tag = GigTag.new
        gig_tag.gig_id = gig.id
        gig_tag.tag_id = gig.tag_id
        gig_tag.save!
      end
    end
    remove_column :gigs, :tag_id
  end
  def down
    add_column :gigs, :tag_id, :integer
    GigTag.all.each do |gig_tag|
      gig = Gig.find(gig_tag.gig_id)
      gig.tag_id = gig_tag.tag_id
      gig.save!
    end
    drop_table :gig_tags
  end

end
