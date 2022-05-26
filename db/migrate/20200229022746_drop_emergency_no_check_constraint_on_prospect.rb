class DropEmergencyNoCheckConstraintOnProspect < ActiveRecord::Migration[5.2]
  def change
    db.execute "ALTER TABLE prospects DROP CONSTRAINT prospects_emergency_no_check"
  end
end
