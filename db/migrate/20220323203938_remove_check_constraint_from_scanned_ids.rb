class RemoveCheckConstraintFromScannedIds < ActiveRecord::Migration[5.2]
  def up
    execute "ALTER TABLE scanned_ids DROP CONSTRAINT scanned_ids_photo_check"
    execute "ALTER TABLE scanned_ids DROP CONSTRAINT scanned_ids_photo_check1"
  end
  def down
    execute "ALTER TABLE scanned_ids ADD CONSTRAINT scanned_ids_photo_check CHECK (((photo)::text ~ '^[A-Za-z0-9._%-]+\.(jpg|jpeg|gif|png)$'::text))"
    execute "ALTER TABLE scanned_ids ADD CONSTRAINT scanned_ids_photo_check1 CHECK (((photo)::text ~ '^[A-Za-z0-9._%-]+\.(jpg|jpeg|gif|png)$'::text))"
  end
end
