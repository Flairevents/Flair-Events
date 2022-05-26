class ScannedId < ApplicationRecord
  belongs_to :prospect

  validates_presence_of :prospect_id, :photo
  validates_format_of   :photo, with: /\A\w+\.(jpg|jpeg|gif|png|pdf)\z/
  validates_uniqueness_of :photo
  
  after_destroy do |scanned_id|
    `rm #{Flair::Application.config.shared_dir}/scanned_ids/#{scanned_id.photo}`
    `rm #{Flair::Application.config.shared_dir}/scanned_ids_large/#{scanned_id.photo}`
  end

  def rotate
    [:scanned_ids, :scanned_ids_large].each do | folder |
      path = "#{ Flair::Application.config.shared_dir }/#{ folder }/#{ self.photo }"
      MiniMagick::Image.new(path) do | image |
        image.rotate '90'
      end if File.exists? path
    end
  end

end
