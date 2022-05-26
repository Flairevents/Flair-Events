class RenameAccomEmailToAccomPhone < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :accom_email, :accom_phone
  end
end
