require 'csv'

class CreateClients < ActiveRecord::Migration
  def up
    clients = {}
    skip_key = "*SKIP*"
    csv = CSV.read('db/migrate/20161013001618_clients.csv')  
    csv.each do |row|
      clients[row[0]] = ((row[2] && row[2] != '') ? skip_key : row[1])
    end

    Event.all.each do |e|
      # Skip events with no client specified
      if e.client && e.client != ''
        client = e.client.try(:strip)
        name = clients[client]
        #Check if we defined an action for this client
        if name
          #Only process client if we are not suppose to skip it
          if name != skip_key
            ##### Create the client if it doesn't already exist
            c = Client.where(name: name).first
            if !c
              c = Client.new
              c.name = name
              c.save
            end 
            ##### Associate the client with the event 
            ec = EventClient.new
            ec.event_id = e.id
            ec.client_id = c.id         
            ec.save
          end
        else
          raise "Don't know what to do with client '#{client}' ->'#{name}'"
        end
      end
    end
  end

  def down
    Client.destroy_all
    EventClient.destroy_all
  end 
end
