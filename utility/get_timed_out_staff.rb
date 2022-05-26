#!/usr/bin/env ruby

require 'rubygems'
require 'json'

ARGV.each do |file|
  File.open(file).each do |line|
    if /\AStarted/.match(line)
      if /\AStarted POST "\/staff\/application"/.match(line)
        application = true
      else
        application = nil
        parameters = nil
        filter_chain = nil
      end
    end
    if application 
      if /\A\s+Parameters:/.match(line)
        parameters = line
      end
      if /\AFilter chain halted as :ensure_prospect_logged_in rendered or redirected/
        filter_chain = nil
      end
      if filter_chain && parameters
        puts JSON.parse(parameters).inspect
      end
    end
  end
end
