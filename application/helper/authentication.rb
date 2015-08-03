module Ramaze::Helper
  module Authentication

    def check_simple_http_authentication()
      simple_auth = request.env['HTTP_AUTHORIZATION']
      return nil if simple_auth.nil? || simple_auth.empty?

      auth_type, auth_base64_creds = simple_auth.split(' ')
      return nil unless 'basic'.eql?(auth_type.downcase) || 'simple'.eql?(auth_type.downcase)

      username, password = Base64.decode64(auth_base64_creds).split(':')
      return { username: username, password: ::DTK::DataEncryption.hash_it(password), c: ret_session_context_id(), access_time: Time.now() }
    end

    def login_without_response(cred)
      login_response = nil
      begin
        login_response = user_login(cred)
      rescue ::Sequel::DatabaseDisconnectError, ::Sequel::DatabaseConnectionError => e
        # do nothing
      end
      return false unless login_response

      current_session = ::DTK::CurrentSession.new
      current_session.set_user_object(user_object())
      session.store(:last_ts, Time.now.to_i)

      return true
    end

    def handle_and_return_authentication(cred, redirect_url = nil)
      begin
        login_response = user_login(cred)
      rescue ::Sequel::DatabaseDisconnectError, ::Sequel::DatabaseConnectionError => e
        respond(e, 403)
      end

      current_session = ::DTK::CurrentSession.new
      current_session.set_user_object(user_object())

      # expire time set, we use Innate session for this
      session.store(:last_ts, Time.now.to_i)

      # expires tag + 3 hours
      cookie_expire_time = (Time.now + 3 * 3600)
      encrypt_info = ::AESCrypt.encrypt("#{user_object()[:id]}_#{cookie_expire_time.to_i}_#{user_object()[:c]}", ::DTK::Controller::ENCRYPTION_SALT, ::DTK::Controller::ENCRYPTION_SALT)

      unless R8::Config[:session][:cookie][:disabled]
        # set session cookie, we set both expire time and user id in it
        response.set_cookie(
          'dtk-user-info',
          value: Base64.encode64(encrypt_info),
          expires: cookie_expire_time
        )
      end

      if login_response
        rest_request? ? { content: nil } : redirect(redirect_url || R8::Config[:login][:redirect])
      else
        auth_violation_response()
      end
    end

  end
end