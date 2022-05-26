class RemoveProspectsStatusCheckConstraintFromProspect < ActiveRecord::Migration
  def change
    execute 'ALTER TABLE prospects DROP CONSTRAINT prospects_status_check'
  end
end
