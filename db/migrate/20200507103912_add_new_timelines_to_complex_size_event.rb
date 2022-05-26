class AddNewTimelinesToComplexSizeEvent < ActiveRecord::Migration[5.2]
  def up
    EventTaskTiming.where(size: EventSize.find_by_name("Complex")).destroy_all
    tasks = [
        ["Event Admin",             2,  "Complex"],
        ["Send FD's",               2,  "Complex"],
        ["Confirm Final Team",      3,  "Complex"],
        ["Send Email/Call backs",   5,  "Complex"],
        ["Logistics Confirm/Cx",    5,  "Complex"],
        ["Clear Replies",           5,  "Complex"],
        ["Send E-mail Confirm",     8,  "Complex"],
        ["Onsite Leadership",       9,  "Complex"],
        ["Planning Meeting",       10,  "Complex"],
        ["Client Contact",         11,  "Complex"],
        ["Marketing",              12,  "Complex"],
        ["Assess Numbers",         15,  "Complex"],
        ["Key Players",            16,  "Complex"],
        ["Send Reserve/Booked",    18,  "Complex"],
        ["Work Team",              19,  "Complex"],
        ["Send Reserve/Booked",    22,  "Complex"],
        ["Send Beepro",            25,  "Complex"],
        ["Prep Beepro",            26,  "Complex"],
        ["Vet Requests",           29,  "Complex"],
        ["Planning Meeting",       30,  "Complex"],
        ["Key Players",            31,  "Complex"],
        ["Marketing",              43,  "Complex"],
        ["Key Players",            45,  "Complex"],
        ["Assess Numbers",         56,  "Complex"],
        ["Vet Requests",           63,  "Complex"],
        ["Logistics Bookings",     79,  "Complex"],
        ["Marketing",              80,  "Complex"],
        ["Open on Website",        81,  "Complex"],
        ["Planning Meeting",      106,  "Complex"],
    ]
    tasks.each do |task|
      EventTaskTiming.create!(template: EventTaskTemplate.find_by_task(task[0]), days: task[1], size: EventSize.find_by_name(task[2]), type: 'BEFORE_EVENT_START')
    end
  end

  def down
    EventTaskTiming.where(size: EventSize.find_by_name("Complex")).destroy_all
  end
end
