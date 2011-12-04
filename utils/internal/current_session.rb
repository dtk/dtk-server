module XYZ
  class CurrentSession
    extend Innate::StateAccessor
    state_accessor :user_object, :auth_filters
    def get_user_object()
      user_object
    end


    def get_username()
      get_user_object()[:username]
    end

    def self.get_username()
       CurrentSession.new.get_username()
    end

    def set_user_object(user_object)
      self.user_object = user_object
    end
    def get_auth_filters()
      auth_filters
    end

    def set_auth_filters(*array_auth_filters)
      self.auth_filters = array_auth_filters
    end
  end
end
