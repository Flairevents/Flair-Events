class RemoveAddress2ConstraintFromProspect < ActiveRecord::Migration
  def up
   execute "ALTER TABLE prospects DROP CONSTRAINT prospects_address2_check"
  end
  def down
   execute "ALTER TABLE prospects ADD CHECK (address2 IS NULL OR address2 <> '')"
  end
end
