class AddNewTimelinesToOneDaySimpleSizeEvent < ActiveRecord::Migration[5.2]
  def up
    EventTaskTemplate.create(task: "Send Call backs", notes: "Team to call to confirm working")
    EventTaskTemplate.create(task: "Send E-mail Confirm", notes: "")
    EventTaskTemplate.create(task: "Send Shift Emails", notes: "Offers/reserved/booked - what suits event and team")
    EventTaskTemplate.create(task: "Re-ases Plan")

    EventTaskTiming.where(size: EventSize.find_by_name('1 Day Simple')).destroy_all
    tasks = [
        ["Event Admin", 2, "1 Day Simple"],
        ["Confirm Team & FD'S", 3, "1 Day Simple"],
        ["Send Call backs", 5, "1 Day Simple"],
        ["Client / Logistics", 5, "1 Day Simple"],
        ["Send E-mail Confirm", 8, "1 Day Simple"],
        ["Work Team", 16, "1 Day Simple"],
        ["Send Booked/Shift Offer", 19, "1 Day Simple"],
        ["Send Shift Emails", 22, "1 Day Simple"],
        ["Re-ases Plan", 29, "1 Day Simple"],
        ["Vet Requests", 36, "1 Day Simple"],
        ["Start Event", 44, "1 Day Simple"],
    ]
    tasks.each do |task|
      EventTaskTiming.create!(template: EventTaskTemplate.find_by_task(task[0]), days: task[1], size: EventSize.find_by_name(task[2]), type: 'BEFORE_EVENT_START')
    end
  end

  def down
	  EventTaskTiming.where(size: EventSize.find_by_name('1 Day Simple')).destroy_all
  end
end
