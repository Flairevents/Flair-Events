class AddBarLicenseIssuedByToProspect < ActiveRecord::Migration
  def  up
    add_column :prospects, :bar_license_issued_by, :string
  end
  def  down
    remove_column :prospects, :bar_license_issued_by
  end
end
