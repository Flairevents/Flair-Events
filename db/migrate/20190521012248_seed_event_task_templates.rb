class SeedEventTaskTemplates < ActiveRecord::Migration[5.2]
  def up
    EventTaskTemplate.create! task: "Client Contact",          notes: "Re-confirm numbers & timings. Any missing info?"
    EventTaskTemplate.create! task: "Open on Website",         notes: "Check logos, description etc."
    EventTaskTemplate.create! task: "Send FD's",               notes: ""
    EventTaskTemplate.create! task: "Send Email/Call backs",   notes: ""
    EventTaskTemplate.create! task: "Vet Requests",            notes: ""
    EventTaskTemplate.create! task: "Interviews",              notes: ""
    EventTaskTemplate.create! task: "Clear Replies",           notes: ""
    EventTaskTemplate.create! task: "Assess Numbers",          notes: "Do we have enough?"
    EventTaskTemplate.create! task: "Planning Meeting",        notes: "With whom?"
    EventTaskTemplate.create! task: "Confirm Final Team",      notes: "Timings?"
    EventTaskTemplate.create! task: "External Ads",            notes: "Where to?"
    EventTaskTemplate.create! task: "Send Reserve/Booked",     notes: ""
    EventTaskTemplate.create! task: "Send Booked/Shift Offer", notes: ""
    EventTaskTemplate.create! task: "Prep Beepro",             notes: "What purpose? Sign Up? Pick Shift/Days/Job?"
    EventTaskTemplate.create! task: "Send Beepro",             notes: "Team or Apps or both?"
    EventTaskTemplate.create! task: "Assess Team",             notes: "Is it good enough?"
    EventTaskTemplate.create! task: "Key Players",             notes: "TLs/Sups/Mgrs - booked/reserved?"
    EventTaskTemplate.create! task: "Applicant Push",          notes: "How?"
    EventTaskTemplate.create! task: "Event Admin",             notes: "What's required and for whom?"
    EventTaskTemplate.create! task: "Photo Check",             notes: ""
    EventTaskTemplate.create! task: "Send Shift Offer Email",  notes: ""
    EventTaskTemplate.create! task: "Submit Accred Info",      notes: "Deadline?"
    EventTaskTemplate.create! task: "Send Assignment Email",   notes: ""
    EventTaskTemplate.create! task: "Cull Non-Responses",      notes: "How do we look on Numbers? Marketing Needed."
    EventTaskTemplate.create! task: "Marketing",               notes: "Internal or External? What & to whom?"
    EventTaskTemplate.create! task: "Logistics Confirm/Cx",    notes: "What needs organising?"
    EventTaskTemplate.create! task: "Client Debrief",          notes: ""
    EventTaskTemplate.create! task: "Logistics Bookings",      notes: "What and for whom?"
    EventTaskTemplate.create! task: "Onsite Leadership",       notes: "Discussion, explore all onsite leadership planning"
  end
  def down
    EventTaskTemplate.destroy_all
  end
end
