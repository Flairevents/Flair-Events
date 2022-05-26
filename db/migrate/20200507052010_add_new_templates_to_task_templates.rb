class AddNewTemplatesToTaskTemplates < ActiveRecord::Migration[5.2]
  def up
    EventTaskTemplate.create(task: "Confirm Team & FD'S", notes: "Complete all tasks")
    EventTaskTemplate.create(task: "Team Comms", notes: "Prepare & confirm your team for the pending work contract.")
    EventTaskTemplate.create(task: "Client / Logistics", notes: '')
    EventTaskTemplate.create(task: "Work Team", notes: "select, communicate, book in team or add tasks.")
    EventTaskTemplate.create(task: "Start Event", notes: "Open on website or advertise key talent")

    EventTaskTiming.where(size: EventSize.find_by_name("Small 1-10")).destroy_all
    tasks = [
		    ["Event Admin",               2,    "Small 1-10"],
		    ["Send FD's",                 4,    "Small 1-10"],
		    ["Confirm Final Team",        5,    "Small 1-10"],
		    ["Client Contact",            5,    "Small 1-10"],
		    ["Send Email/Call backs",     9,    "Small 1-10"],
		    ["Open on Website",           17,   "Small 1-10"],
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
