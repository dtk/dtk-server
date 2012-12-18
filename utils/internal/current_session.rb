module DTK
  # Wrapper for Ramaze::Session object, user credentials are set in 
  # user_controller#process_login
  # Also timeout logic can be found in AuthController
  class CurrentSession
    class << self
      def method_missing(name,*args)
        instance = Instance.new
        instance.respond_to?(name) ? instance.send(name,*args) : super
      end
      def respond_to?(name)
        instance = Instance.new
        instance.respond_to?(name)||super
      end

      def get_instance()
        Instance.new
      end
    end
   private
    class Instance
      extend Innate::StateAccessor
      state_accessor :user_object, :auth_filters
      def get_user_object()
        user_object
      end
      def get_username()
        get_user_object()[:username]
      end
      
      def set_user_object(user_object)
        @user_object = user_object
      end
      def get_auth_filters()
        auth_filters
      end

      def set_auth_filters(*array_auth_filters)
        @auth_filters = array_auth_filters
      end
    end
  end

  class SessionError < Error
  end
end
