class AddThumbnailAndStatusAndDatePublishedToTextBlock < ActiveRecord::Migration
  def change
    add_column :text_blocks, :thumbnail, :string
    add_column :text_blocks, :status, :string
    add_column :text_blocks, :date_published, :datetime
    TextBlock.all.each do |tb|
      unless tb.type == 'terms'
        tb.status = 'PUBLISHED'
        tb.save
      end 
    end
  end
end
