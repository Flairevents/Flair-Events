class DropAnswersTable < ActiveRecord::Migration
  def up
    drop_table :answers
  end
end
