class ShareCodeFile < ApplicationRecord
  belongs_to :prospect

  validates_presence_of :prospect_id, :path
  validates_uniqueness_of :path
  
  after_destroy do |share_code_file|
    `rm #{Flair::Application.config.shared_dir}/prospect_share_codes/#{share_code_file.path}`
  end
end
