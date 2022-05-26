class AddJobToRejectEvents < ActiveRecord::Migration[5.2]
  def change
    add_reference :reject_events, :job, foreign_key: true
  end
end
