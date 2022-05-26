class AddBarAndTrainingToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :bar_experience, :string
    add_column :prospects, :bar_license_type, :string
    add_column :prospects, :bar_license_no, :string
    add_column :prospects, :bar_license_expiry, :date
    add_column :prospects, :training_type, :string
  end

  def down
    remove_column :prospects, :bar_experience, :string
    remove_column :prospects, :bar_license_type, :string
    remove_column :prospects, :bar_license_no, :string
    remove_column :prospects, :bar_license_expiry, :date
    remove_column :prospects, :training_type, :string
  end
end
