class DeleteBarLicenseTypeOnProspect < ActiveRecord::Migration
  def up
    Prospect.all.each do |p|
      if p.bar_license_type
        p.bar_license_type = nil
        p.save
      end
    end
  end

  def down
    puts("You cannot undo what has been done")
  end
end
