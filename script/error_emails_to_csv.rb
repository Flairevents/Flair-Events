require 'json'
require ::File.expand_path('../config/environment', __dir__)

puts("###########################")

subject = nil
prospect_param = nil
prospect_id = nil
update_attempt = nil
changes = {}
deactivate = []

File.readlines('FlairErrors.txt').each do |line|
  if match = line.match(/(^Subject:.*$)/)
    subject = match.captures.first
    parameters = nil
    update_attempt = nil
  end
  if subject
    if subject.match(/deactivate_account/)
      if match = line.match(/"account"=>([0-9]+)/)
        account_id = JSON.parse(match.captures.first.gsub(/'/, "\'").gsub(/=>/, ':'))
        prospect_id = Account.find(account_id).user_id 
        deactivate << prospect_id unless deactivate.include? prospect_id
      end
    end
    if subject.match(/update_prospect/)
      if match = line.match(/Parameters\s*:\s*(.*)/)
        parameters = JSON.parse(match.captures.first.gsub(/'/, "\'").gsub(/=>/, ':'))
        prospect_params = parameters['prospect']
        prospect_id = parameters['id']
      end
      if match = line.match(/^: UPDATE "prospects" SET (.*)$/)
        update_attempt = match.captures.first
      end
      if parameters && update_attempt
        params_to_update = update_attempt.gsub(/\"/, '').gsub(/ = \$[0-9]/, '').gsub(/ WHERE.*/, '').split(', ') - ['updated_at']
        params_to_update = params_to_update - ['address2'] if params_to_update.include?('address2') && prospect_params['address2'] == ""
        if params_to_update.length > 0
          changes[prospect_id] ||={}
          params_to_update.each do |param|
            key = param
            val = prospect_params[param]
            if param == 'nationality_id'
              key = 'nationality'
              val = Country.find(val).name
            end  
            changes[prospect_id][key] = val
          end
        end
        subject = nil #Done!
      end
    end
  end
end

puts "##### TO CHANGE #####"
changes.each do |id, params|
  prospect = Prospect.find(id)
  puts("#{prospect.first_name} #{prospect.last_name}: (#{id}) changes: #{params}")
end

puts "##### TO DEACTIVATE #####"
deactivate.each do |id|
  prospect = Prospect.find(id)
  puts("#{prospect.first_name} #{prospect.last_name}: (#{id})")
end
