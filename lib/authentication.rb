module Authentication
  private

  module Accessors
    def account
      @account ||= Account.includes(:user).find(session[:account]) rescue nil
    end
    def current_user
      @current_user ||= account.try(:user)
    end
    def last_active
      session[:last_active]
    end
  end

  # From within various controllers, we can require that a certain type of login is required to see
  #   certain pages

  def self.included(cls)
    cls.send(:include, Accessors)

    def cls.only_accessible_to_prospects(options={})
      timeout = options.delete(:timeout) || 30.minutes
      before_action :ensure_prospect_logged_in, options
      define_method(:ensure_prospect_logged_in) do
        expire_old_login(timeout)
        unless current_user.is_a?(Prospect)
          if request.xhr?
            if request.format.to_s == 'text/html'
              render plain: "<script>window.location = '/login'</script>"
            elsif request.format.to_s == 'application/json'
              render json: {status: 'error', message: 'Your login has expired. Please <a href="/login">log in again</a>.'}
            else
              render plain: "Not logged in", status: :forbidden
            end
          else
            redirect_to "/login", flash: { target: request.url }
          end
        end
        if current_user.is_a?(Prospect) &&  current_user.try(:status) == 'HAS_BEEN'
          logout_account
          redirect_to "/login"
        end
      end
    end

    def cls.only_accessible_to_client_contacts(options={})
      timeout = options.delete(:timeout) || 30.minutes
      before_action :ensure_client_contact_logged_in, options
      define_method(:ensure_client_contact_logged_in) do
        expire_old_login(timeout)
        unless current_user.is_a?(ClientContact)
          if request.xhr?
            if request.format.to_s == 'text/html'
              render plain: "<script>window.location = '/client/login'</script>"
            elsif request.format.to_s == 'application/json'
              render json: {status: 'error', message: 'Your login has expired. Please <a href="/login">log in again</a>.'}
            else
              render plain: "Not logged in", status: :forbidden
            end
          else
            redirect_to client_login_path, flash: { target: request.url }
          end
        end
      end
    end

    def officer_login_html
      result = <<END_HTML
Your login has expired.<br/>
<form action="/office/login">
  <div style="margin:0;padding:0;display:inline">
    <input name="authenticity_token" type="hidden" value="#{form_authenticity_token}">
  </div>
  <p>
    <label>E-mail address</label>
    <input id="login_email" name="login_email" type="text">
  </p>
  <p>
    <label>Password</label>
    <input id="login_password" name="login_password" type="password">
  </p>
  <p>
    <input name="commit" type="submit" value="Login" onclick="$.ajax({url: '/office/relogin', method: 'POST', data: $('.flash form').serialize()}).done(function() { $('.flash-backing').fadeOut() })">
  </p>
</form>
END_HTML
      result.gsub("\n", '')
    end

    def cls.only_accessible_to_officers(options={})
      before_action :ensure_officer_logged_in, options
      def ensure_officer_logged_in
        expire_old_login
        unless current_user.is_a?(Officer) && !current_user.archived?
          if request.xhr?
            if request.format.to_s == 'application/json'
              render json: {status: 'error', message: officer_login_html}
            else
              render plain: "Not logged in", status: :forbidden
            end
          else
            redirect_to "/office/login"
          end
        end
      end
    end

    def cls.only_accessible_to_managers(options={})
      before_action :ensure_manager_logged_in, options
      def ensure_manager_logged_in
        expire_old_login
        unless current_user.is_a?(Officer) && current_user.manager?
          if request.xhr?
            if request.format.to_s == 'application/json'
              render json: {status: 'error', message: officer_login_html}
            else
              render plain: "Not logged in", status: :forbidden
            end
          else
            redirect_to "/office/login"
          end
        end
      end
    end
  end

  def expire_old_login(timeout=nil)
    if current_user
      timeout ||= (current_user.is_a?(Officer) ? 2.week : 1.week)
      if !last_active || (last_active + timeout) < Time.now
        logout_account
      else
        session[:last_active] = Time.now
      end
    end
  end

  def logout_account
    if @current_user.is_a?(Officer) && (session_log = SessionLog.where(account: @account).order(:login_time).last)
      session_log.logout_time = DateTime.now unless session_log.try(:logout_time)
      session_log.save
    end
    @account = @current_user = nil
    session[:account] = session[:last_active] = nil
  end

  def login_account(account)
    logout_account # if user was already logged in using another account, log that one out first
    if account.try(:user).try(:is_a?, Officer)
      session_log = SessionLog.new(account: account, login_ip: request.remote_ip, login_time: DateTime.now)
      if (g = Geocoder.search(request.remote_ip).try(:first))
        session_log.login_ip_coordinates = g.coordinates.join(',') if g.try(:coordinates).present?
        location_array = []
        location_array << g.city    if g.try(:city)
        location_array << g.region  if g.try(:region)
        location_array << g.country if g.try(:country)
        session_log.login_ip_location = location_array.join(', ') if location_array.length > 0
      end
      session_log.save
    end
    session[:account] = account.id
    session[:last_active] = Time.now
  end

  def login_as_prospect(email, password)
    if user = Prospect.find_by_email(email)
      if user.status == 'HAS_BEEN'
        :forbidden
      else
        login_as_user(user, password)
      end
    else
      :no_such_account
    end
  end

  def login_as_client_contact(email, password)
    if user = ClientContact.find_by_email(email)
      login_as_user(user, password)
    else
      :no_such_account
    end
  end

  def login_as_officer(email, password)
    if user = Officer.find_by_email(email)
      if user.archived?
        :forbidden
      else
        login_as_user(user, password)
      end
    else
      :no_such_account
    end
  end

  # 'user' is either a Prospect or an Officer
  def login_as_user(user, password)
    account = user.account
    if account.nil?
      # Prospect/Officer was manually created in DB, but has no Account yet
      :not_initialized
    elsif !account.confirmed_email
      :not_confirmed
    elsif account.locked
      :locked_out
    elsif account.authenticate_by_password(password)
      login_account(account)
      account.failed_attempts = 0
      account.save!
      :success
    else
      account.failed_attempts += 1

      if account.failed_attempts > 10
        account.locked = true
        account.save!
        :locked_out
      else
        account.save!
        :wrong_password
      end
    end
  end

  # workaround for controllers which have a 'cookies' action
  def _cookies
    ActionController::Base.instance_method(:cookies).bind(self).call
  end

  def login_by_token(one_time_token)
    if account = Account.where(one_time_token: one_time_token).first
      account.one_time_token_used!
      login_account(account)
      true
    else
      false
    end
  end
end
