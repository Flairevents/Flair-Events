class AddVmAndEmColumnsIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :voice_message, :boolean, null: false, default: false
    add_column :prospects, :e_mail, :string
    add_column :prospects, :missed_interview, :date
    add_column :prospects, :txt, :date
    add_column :prospects, :head_quarter, :string
  end
end
