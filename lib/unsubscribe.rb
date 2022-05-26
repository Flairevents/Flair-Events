# This script is run by postfix when it receives an incoming e-mail to an address like:
# <unsubscribe.*@unsubscribe.eventstaffing.co.uk>
# See /etc/postfix/master.cf and /etc/postfix/virtual.regex
# The content of the incoming mail can be read from STDIN

# TODO: Use syslog to log an error message if we fail anywhere here
require 'mail'
require 'sequel'
require 'yaml'
require 'erb'

ENV['RAILS_ENV']||='production'
db_config = YAML.load_file(File.expand_path('../config/database.yml', __dir__))[ENV['RAILS_ENV']]
DB = Sequel.connect(db_config)
testing = false

begin
  unless testing
    message_in = Mail.new(STDIN.read)
  else
    message_in = Mail.new do
      #to 'unsubscribe-invalid-token@unsubscribe.eventstaffing.co.uk'
      to 'unsubscribe-5MBJV4vVUtrwEpt3Rjpb@unsubscribe.eventstaffing.co.uk'
      #from 'alexis.szabo2@hotmail.com'
      #from 'Alexis Szabo <alexis.szabo2@hotmail.com>'
      from 'Alexis Szabo <alexis@appybara.com>'
      subject 'Unsubsribe Me'
      text_part do
        body 'This is plain text'
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
     end
    end
  end
  ##### Why do we check for the token if we fall back to the from address?
  #####  - If the person has a redirect (ie. they're registered as @hotmail.com,
  #####    but it's forwarded to and they reply from @outlook.com
  ##### Why do we use the from address instead of relying only on the more-secure token?
  #####  - The Flair office staff sometimes send 'marketing' emails to alert
  #####    employees/applicants of upcoming events. These are sent as a
  #####    regular email, so won't include a token
  ##### IMPLICATIONS:
  #####  - 'From addresses' can be spoofed, so we cannot directly set unsubscribe
  #####    preferences based on the from address.
  #####  - Instead, in all cases, we will send an email to the email in their
  #####    account, which contains an unsubsribe link with token
  #####  - In the case that we can't find an account, we will just send to their
  #####    from email address with a tokenless link to the unsubscribe page.
  #####    Then they can login to set their unsubscribe preferences

  ##########################################
  ##### Define variables for ERB views #####
  #########################################

  account = nil
  ##### Preferred Method: If the person has a token, use that
  if (token = message_in.to.first[/unsubscribe-([^@]+)/, 1]) && (account = DB[:accounts].where(unsubscribe_token: token).first)
    @person = DB[:prospects].where(id: account[:user_id]).first
  ##### Otherwise, match their account by their email address
  else
    @person = DB[:prospects].where(email: message_in.from).first
    account = DB[:accounts].where(user_id: @person[:id]).first if @person
  end
  name = (@person && @person[:first_name]) || message_in[:from].display_names.first
  @salutation = "Hi#{name ? " #{name}" : ''},"
  @base_url = "https://eventstaffing.co.uk"
  @unsubscribe_url = "#{@base_url}/staff/unsubscribe#{account ? "?token=#{account[:unsubscribe_token]}" : ''}"

  ############################
  ##### Generate Message #####
  ############################

  message_out_body_html  = ERB.new(File.read(File.join(__dir__, '../app/views/staff_mailer/unsubscribe_acknowledgement.html.erb'))).result
  message_out_body_text = message_out_body_html.gsub( %r{</?[^>]+?>}, '' )
  message_out_headers = {}
  message_out_headers['List-Unsubscribe'] = "<mailto:unsubscribe-#{token||''}@unsubscribe.eventstaffing.co.uk>"
  message_out_to = (@person && @person[:email]) || message_in.from
  message_out = Mail.new do
    headers message_out_headers
    to      message_out_to
    from    'Flair Events <communications@eventstaffing.co.uk>'
    subject 'Please Finalize Your Unsubscribe Request'
    text_part do
      body message_out_body_text
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body         message_out_body_html
    end
  end

  ######################
  ###### Send Mail #####
  ######################

  message_out.delivery_method :sendmail
  message_out.deliver
rescue Exception => e
  t = Time.now
  DB[:admin_log].insert(type: 'unsubscribe_failed', data: {message: message_in, exception: e.message}.to_json, updated_at: t, created_at: t)
end
