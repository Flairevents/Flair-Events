class ScannedDbs < ApplicationRecord
  belongs_to :prospect

  validates_presence_of :prospect_id, :photo
  validates_format_of   :photo, with: /\A\w+\.(jpg|jpeg|gif|png|pdf)\z/
  validates_uniqueness_of :photo

  after_destroy do |scanned_dbs|
    `rm #{Flair::Application.config.shared_dir}/scanned_dbses/#{scanned_dbs.photo}`
  end

  def rotate
    path = "#{ Flair::Application.config.shared_dir }/scanned_dbses/#{ self.photo }"
    MiniMagick::Image.new(path) do | image |
      image.rotate '90'
    end if File.exists? path
  end
  
end
