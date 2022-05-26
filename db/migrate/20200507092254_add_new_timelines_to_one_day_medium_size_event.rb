class AddNewTimelinesToOneDayMediumSizeEvent < ActiveRecord::Migration[5.2]
  def up
    EventTaskTemplate.create(task: "Marketing (Re-ases Plan)", notes: "")
    EventTaskTemplate.create(task: "Send Shift Selections", notes: "")

    EventTaskTiming.where(size: EventSize.find_by_name("Medium+")).destroy_all
    tasks = [
        ["Event Admin",               2,  "Medium+"],
        ["Send FD's",                 2,  "Medium+"],
        ["Confirm Final Team",        3,  "Medium+"],
        ["Send Call backs",           5,  "Medium+"],
        ["Clear Replies",             5,  "Medium+"],
        ["Send E-mail Confirm",       8,  "Medium+"],
        ["Client / Logistics",        8,  "Medium+"],
        ["Onsite Leadership",         11, "Medium+"],
        ["Assess Team",               12, "Medium+"],
        ["Send Shift Emails",         16, "Medium+"],
        ["Send Shift Selections",     19, "Medium+"],
        ["Prep Beepro",               22, "Medium+"],
        ["Vet Requests",              22, "Medium+"],
        ["Marketing (Re-ases Plan)",  29, "Medium+"],
        ["Vet Requests",              36, "Medium+"],
        ["Start Event",               54, "Medium+"],
    ]
    tasks.each do |task|
      EventTaskTiming.create!(template: EventTaskTemplate.find_by_task(task[0]), days: task[1], size: EventSize.find_by_name(task[2]), type: 'BEFORE_EVENT_START')
    end
  end

  def down
    EventTaskTiming.where(size: EventSize.find_by_name("Medium+")).destroy_all
  end
end


