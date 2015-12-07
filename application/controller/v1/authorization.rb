module DTK
  module V1
    class AuthorizationController < Controller

      def rest__login
        cred = { username: request.params['username'], password: DataEncryption.hash_it(request.params['password']), c: ret_session_context_id(), access_time: Time.now() }
        handle_and_return_authentication(cred)
      end

      def rest__logout
        user_logout
        { content: nil }
      end

    end
  end
end