class AddLastLoginAndPreviousLoginToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :last_login, :date
    add_column :prospects, :previous_login, :date
  end
end
