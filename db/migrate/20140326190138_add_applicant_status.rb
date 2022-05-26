class AddApplicantStatus < ActiveRecord::Migration
  def up
    add_column :prospects, :applicant_status, :string
  end

  def down
    remove_column :prospects, :applicant_status
  end
end
