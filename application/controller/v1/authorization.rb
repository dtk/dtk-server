module DTK
  module V1
    class AuthorizationController < AuthController

      def rest__login
        cred = { username: params['username'], password: DataEncryption.hash_it(params['password']), c: ret_session_context_id(), access_time: Time.now() }
        handle_and_return_authentication(cred)
      end

    end
  end
end