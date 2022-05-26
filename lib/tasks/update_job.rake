namespace :job do
  desc "Update job"
  task :update => :environment do
    @gigrequests = GigRequest.all
    count = 1
    @gigrequests.each do |gig_request|
      puts "job #{count}"
      count = count+1
      @event_id = gig_request.event_id
      @event = Event.find_by(id: @event_id)
      gig_request.update!(job_id: @event.jobs.first.id) if @event.jobs.first.present?
      sleep(1)
    end
  end
end
