#!/usr/bin/env ruby

people = []
File.open('/var/www/flair/current/log/temp/timed_out.txt').each do |line|
  line.chomp!

  if p=Prospect.where(email: line)[0] 
    if p.applicant_status && p.applicant_status == 'HOLDING'
      people << p
    end
  else
    puts "Couldn't find prospect for: #{line}"
  end
end

people.each do |p|
  puts "#{p.first_name} #{p.last_name} : #{p.email}"
end
