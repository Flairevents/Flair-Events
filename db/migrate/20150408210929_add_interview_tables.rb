class AddInterviewTables < ActiveRecord::Migration
  def up
    create_table :bulk_interviews do |t|
      t.string  :name
      t.string  :venue
      t.string  :positions
      t.string  :address
      t.string  :city
      t.string  :post_code
      t.string  :note_for_applicant #This should have been a text field with limit-nil. Not a string. This is fixed in a later migration
      t.date    :date_start
      t.date    :date_end
      t.timestamps null: false
    end

    create_table :bulk_interview_events do |t|
      t.belongs_to :bulk_interview, index: true
      t.belongs_to :event, index: true
      t.timestamps null: false
    end

    create_table :interview_blocks do |t|
      t.integer :bulk_interview_id, null:false
      t.date    :date
      t.time    :time_start
      t.time    :time_end
      t.integer :slot_mins
      t.integer :number_of_slots
      t.integer :number_of_applicants_per_slot
      t.timestamps null: false
    end

    create_table :interview_slots do |t|
      t.integer :interview_block_id, null:false
      t.integer :index
      t.time    :time_start
      t.time    :time_end
      t.integer :interviews_count, null:false, default: 0
      t.timestamps null: false
    end

    create_table :interviews do |t|
      t.integer :prospect_id, null:false
      t.integer :interview_slot_id, null:false
      t.timestamps null:false
    end
  end

  def down
    drop_table :bulk_interviews
    drop_table :bulk_interview_events
    drop_table :interview_blocks
    drop_table :interview_slots
    drop_table :interviews
  end
end
