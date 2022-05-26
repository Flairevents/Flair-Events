require 'base64'

module Api
  module V1
    class ApiController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      #Authenticate all requests (except for the login method in the inheriting class)
      before_action :authenticate, except: [:login, :log_error, :test_token]

      wrap_parameters false

      def test_token
        puts("it's grrreat!")
      end

      def log_error
        e = StandardError.new params[:message]
        ##### We might need to modify the stack string to give what Ruby excpects
        e.set_backtrace params[:stacktrace].split('\n')

        data = {}
        data[:source]    = params[:source] if params[:source]
        data[:user]      = params[:user] if params[:user]
        data[:line]      = params[:line] if params[:line]
        data[:column]    = params[:column] if params[:column]
        data[:sourceURL] = params[:sourceURL] if params[:sourceURL]
        data[:datetime]  = params[:datetime] if params[:datetime]

        if Rails.env == 'development'
          puts '----------------------'
          puts 'Logging Received Error'
          puts '----------------------'
          puts
          puts e.message
          puts
          puts '----------------------'
          puts 'Backtrace:'
          puts '----------------------'
          puts
          puts e.backtrace
          puts
          puts '----------------------'
          puts 'Data:'
          puts '----------------------'
          puts
          puts data.inspect
          puts
          puts '----------------------'
        else
          ExceptionNotifier.notify_exception(e, {data: data})
        end
        render json: {status: 'ok'}
      end

      protected

      # Authenticate the user with token based authentication
      def authenticate
        authenticate_token || render_unauthorized
      end

      def authenticate_token
        authenticate_with_http_token do |token, options|
          @current_user = Account.find_by(authentication_token: token).try(:user)
        end
      end

      def render_unauthorized(realm = "API")
        self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
        render json: 'Bad credentials', status: :unauthorized
      end

      # lib/authentication.rb already implements a very similar login method
      # We aren't using it because it saves data in the Rails session, and we don't need
      #   or want to use the session
      # Only Certain People can access Certain APIs.
      # Implement a login method for each specific API controller that will call api_login
      def api_login(user, password)
        account = user.account
        if account.nil?
          render json: {status: 'error', message: "Account Not Initialized"}, status: :forbidden
        elsif !account.confirmed_email
          render json: {status: 'error', message: "Must Confirm E-Mail"}, status: :forbidden
        elsif account.locked
          render json: {status: 'error', message: "Account locked. Please Contact Flair Event Staffing"}, status: :forbidden
        elsif account.authenticate_by_password(password)
          account.failed_attempts = 0
          account.save!
          render json: {status: 'ok', token: account.authentication_token, user_id: account.user_id.to_s, user_type: account.user_type}, status: :ok
        else
          account.failed_attempts += 1
          if account.failed_attempts > 10
            account.locked = true
            account.save!
            render json: {status: 'error', message: "Account Locked. Please contact Flair Event Staffing"}, status: :forbidden
          else
            account.save!
            render json: {status: 'error', message: "Incorrect Email or Password"}, status: :unauthorized
          end
        end
      end

      def encode_files_from_objects(objects, path, file_name_attribute, last_time=Date.new(1900,1,1))
        files = []
        objects.each do |object|
          if filename = object.send(file_name_attribute)
            filepath = File.join(path, filename)
            if File.exist?(filepath) && File.mtime(filepath) > last_time
              contents = Base64.encode64(File.read(filepath))
              files << {id: object.id, file_name_attribute.to_sym => filename, contents: contents}
            end
          end
        end
        files
      end

      def decode_to_file(content, path)
        File.open(path, 'wb') do |f|
          f.write(Base64.decode64(content))
        end
      end
    end
  end
end
