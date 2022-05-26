class AddNewTimelinesToSmallSizeEvents < ActiveRecord::Migration[5.2]
  def up
    EventTaskTiming.where(size: EventSize.find_by_name("Small 1-10")).destroy_all
    tasks = [
        ["Event Admin",               2,    "Small 1-10"],
        ["Confirm Team & FD'S",       4,    "Small 1-10"],
        ["Team Comms",                5,    "Small 1-10"],
        ["Client / Logistics",        5,    "Small 1-10"],
        ["Work Team",                 9,    "Small 1-10"],
        ["Work Team",                 17,   "Small 1-10"],
        ["Start Event",               26,   "Small 1-10"],
    ]
    tasks.each do |task|
      EventTaskTiming.create!(template: EventTaskTemplate.find_by_task(task[0]), days: task[1], size: EventSize.find_by_name(task[2]), type: 'BEFORE_EVENT_START')
    end
  end
  def down
    EventTaskTiming.where(size: EventSize.find_by_name("Small 1-10")).destroy_all
  end
end
