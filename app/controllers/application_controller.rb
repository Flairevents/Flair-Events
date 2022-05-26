require 'authentication'

class ApplicationController < ActionController::Base
  # Rails 5.2 puts protect_from_forgery in ActionController::Base, BUT changed the default to :exception
  # We don't want that, so we specify to instead nullify the session
  # In Rails 4.2, the default prepend: true was the default, but default was changed to false in rails 5. We set it true to
  # Make sure protect_from_forgery is done before authentication. Otherwise it might cause the authentication to fail when the token is reset during auth.
  protect_from_forgery with: :null_session, prepend: true
  before_action :login_user_by_token
  before_action :detect_device_variant
  include Authentication

  def heartbeat
    raise 'Heart Beating'
  end

  def login_user_by_token
    return unless params[:token] && params[:action] != "set_password"

    account = Account.find_by(one_time_token: params[:token])
    if account.present?
      account.confirmed_email = true
      account.save
    end
    login_by_token(params[:token])
  end

  def prospect_photo
    if current_user
      prospect = Prospect.find_by_id(params[:id])

      # Officer can view Prospect photos, Prospects can also view their own photo
      if current_user.is_a?(Officer) || prospect.try(:id) == current_user.id
        photo_path = File.join(Flair::Application.config.shared_dir, 'prospect_photos', prospect.present? && prospect.photo ? prospect.photo:  "__NO_PHOTO__")
        # Only throw an error if expected photo doesn't exist if we are in production
        if prospect.present? && prospect.photo.present? && (Rails.env.production? || File.exists?(photo_path))
        # If you need the prospect_photos folder in development, run 'cap production storage:pull' to download all of the assets
        # Then comment out the if statement above and uncomment the one below
        # TODO: Remove original if statement later since we will be working with production photos
        # if prospect.photo.present? && File.exists?(photo_path)
          send_file(photo_path, filename: prospect.photo)
        else
          send_file(Rails.root.join('app', 'assets', 'images', 'no-prospect-photo.png'), filename: 'no-prospect-photo.png')
        end
      else
        render status: :forbidden, body: nil
      end
    else
      redirect_to '/login'
    end
  end

  def flag_photo
    send_file(Rails.root.join('app', 'assets', 'images', "#{params[:id]}.png"), filename: "#{params[:id]}.png")
  end

  def time_clock_report_signature
    time_clock_report = TimeClockReport.find_by_id(params[:id])
    if current_user
      if current_user.is_a?(Officer)
        signature_path = File.join(Flair::Application.config.shared_dir, 'time_clock_report_signatures', time_clock_report.signature || "__NO_SIGNATURE__")
        if time_clock_report.signature.present? && File.exists?(signature_path)
          send_file(signature_path, filename: time_clock_report.signature)
        else
          render nil
        end
      else
        render status: :forbidden, body: nil
      end
    else
      redirect_to '/login'
    end
  end

  protected

  def send_mail(*messages)
    if Rails.env.production?
      SendMailJob.perform_later(*messages.map(&:to_yaml))
      # elsif Rails.env.staging?
      #   messages.each do |m|
      #     m.to = 'error@appybara.com'
      #     m.cc = nil
      #     #m.bcc = ''
      #   end
      #   SendMailJob.perform_later(*messages.map(&:to_yaml))
    else
      messages.each do |m|
        m.to = 'error@appybara.com'
        m.cc = nil
        #m.bcc = ''
      end
      SendMailJob.perform_later(*messages.map(&:to_yaml))

      # messages.each do |message|
      #   puts "*** E-mail sent:"
      #   puts message.to_yaml
      #   puts "***"
      # end
    end
    # SendMailJob.perform_later(*messages.map(&:to_yaml))
    # if Rails.env.production?
    #   SendMailJob.perform_later(*messages.map(&:to_yaml))
    # elsif Rails.env.staging?
    #   messages.each do |m|
    #     m.to = 'error@appybara.com'
    #     m.cc = nil
    #     #m.bcc = ''
    #   end
    #   SendMailJob.perform_later(*messages.map(&:to_yaml))
    # else
    #   messages.each do |message|
    #     puts "*** E-mail sent:"
    #     puts message.to_yaml
    #     puts "***"
    #   end
    # end
  end

  def queue_notification(type, user, data)
    Notification.create(type: type, recipient: user.account, data: data)
  end

  private

  def detect_device_variant
    request.variant = :phone if browser.device.mobile?
  end

  def load_funky_popup_text
    # This was causing an issue with SEO. Popups could be moved to the bottom of the DOM to avoid this.
    @funky_popup_text = TextBlock['funky-popup'].html_safe
  end
end
