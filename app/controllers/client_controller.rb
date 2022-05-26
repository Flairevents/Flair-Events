require 'user_info'

class ClientController < ApplicationController
  layout 'client'

  only_accessible_to_client_contacts except: [:activate, :login]

  ##### In case rails reuses one of the office zone threads, make sure to clear the current user.
  before_action :set_user
  def set_user
    UserInfo.current_user = current_user
    UserInfo.controller_name = controller_name
  end

  def activate
    if token = params[:token]
      if login_by_token(token)
        if current_user.account.password_hash
          flash[:notice] = "You have already activated your account!"
        else
          # Manually created accounts will not yet have a password, so have them set a password
          current_user.account.confirmed_email = true
          current_user.account.save!
          current_user.account_status = 'CONFIRMED_EMAIL'
          current_user.save!
          flash[:notice] = "Welcome! Your email has been confirmed. Please set your password."
          redirect_to client_set_password_path and return
        end
      else
        flash[:error] = "Sorry, something was wrong with your login link! Perhaps you used it already? (It's only good for one time.)"
      end
    end
    redirect_to client_login_path
  end

  def set_password
    if request.post?
      password, confirmation = params[:password].strip, params[:password_confirm].strip
      if password == confirmation
        if Account.password_valid?(password)
          current_user.account.password = password
          current_user.account.save!
          current_user.account_status = 'ACTIVATED'
          current_user.save!
          flash[:notice] = 'Password set!'
          logout_account
          redirect_to client_login_path
        else
          flash.now[:error] = Account.why_invalid?(password)
        end
      else
        flash.now[:error] = "The passwords you entered don't match. Please enter the same password twice."
      end
    end
  end

  def login
    ##### We don't have a login page. But when we do, we can put it here
    flash.keep #preserve flash messages through next redirect. Can remove this when/if we have an actual login page
    redirect_to root_path
  end
end
