module XYZ
  class CurrentSession
    extend Innate::StateAccessor
    state_accessor :user_object, :auth_filters,:access_time
    def get_user_object()
      user_object
    end

    def set_access_time(a_time)
      self.access_time = a_time
    end

    def last_access_time()
      access_time
    end

    def get_username()
      get_user_object()[:username]
    end

    def self.get_username()
       CurrentSession.new.get_username()
    end

    def set_user_object(user_object)
      self.access_time = Time.now
      self.user_object = user_object
    end
    def get_auth_filters()
      auth_filters
    end

    def set_auth_filters(*array_auth_filters)
      self.auth_filters = array_auth_filters
    end
  end

  class SessionError < Error
  end
end
