class RemoveBlurbSignUpMessageFromEvents < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :blurb_sign_up_message, :text, default: ''
  end
end
