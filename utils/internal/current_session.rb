module XYZ
  # Wrapper for Ramaze::Session object, user credentials are set in 
  # user_controller#process_login
  # Also timeout logic can be found in AuthController
  class CurrentSession
    class << self
      def get_username()
        get_user_object()[:username]
      end

      def get_user_object()
        session[:USER][:credentials]
      end

      def set_user_object()
        # [Haris] - Sorry if this broke the code but I did not understand way that user is being set in session
        raise "This is not a proper way to set session user please look into using user_controller#process_login."
      end

      def get_auth_filters()
        # TODO: Rich needs to implement this, with previous implemntation it did not work
      end
    end
  end
end
