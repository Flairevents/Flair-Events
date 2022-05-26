class AddNewTimelinesToLargeSizeEvent < ActiveRecord::Migration[5.2]
  def up
    EventTaskTiming.where(size: EventSize.find_by_name("Large")).destroy_all
    tasks = [
        ["Event Admin",             2,  "Large"],
        ["Send FD's",               2,  "Large"],
        ["Confirm Final Team",      3,  "Large"],
        ["Send Email/Call backs",   5,  "Large"],
        ["Logistics Confirm/Cx",    5,  "Large"],
        ["Clear Replies",           5,  "Large"],
        ["Send E-mail Confirm",     8,  "Large"],
        ["Onsite Leadership",       9,  "Large"],
        ["Client Contact",         11,  "Large"],
        ["Marketing",              12,  "Large"],
        ["Assess Numbers",         15,  "Large"],
        ["Send Reserve/Booked",    18,  "Large"],
        ["Work Team",              19,  "Large"],
        ["Send Reserve/Booked",    22,  "Large"],
        ["Send Beepro",            25,  "Large"],
        ["Prep Beepro",            26,  "Large"],
        ["Vet Requests",           29,  "Large"],
        ["Marketing",              43,  "Large"],
        ["Assess Numbers",         56,  "Large"],
        ["Vet Requests",           63,  "Large"],
        ["Logistics Bookings",     79,  "Large"],
        ["Marketing",              80,  "Large"],
        ["Open on Website",        81,  "Large"],
        ["Planning Meeting",      106,  "Large"],
    ]
    tasks.each do |task|
      EventTaskTiming.create!(template: EventTaskTemplate.find_by_task(task[0]), days: task[1], size: EventSize.find_by_name(task[2]), type: 'BEFORE_EVENT_START')
    end
  end

  def down
    EventTaskTiming.where(size: EventSize.find_by_name("Large")).destroy_all
  end
end
