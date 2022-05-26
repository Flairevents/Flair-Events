class SplitNameIntoFirstNameLastNameOnOfficers < ActiveRecord::Migration[5.2]
  def up
    add_column :officers, :first_name, :string
    add_column :officers, :last_name, :string
    Officer.all.each do |officer|
      names = officer.name.split(/\s/)
      officer.first_name = names.first
      officer.last_name = names.last
      officer.save
    end
    remove_column :officers, :name
    change_column_null :officers, :first_name, false
    change_column_null :officers, :last_name, false
  end
  def down
    add_column :officers, :name, :string
    Officer.all.each do |officer|
      officer.name = "#{officer.first_name} #{officer.last_name}"
      officer.save 
    end
    remove_column :officers, :first_name
    remove_column :officers, :last_name
    change_column_null :officers, :name, false
  end
end
