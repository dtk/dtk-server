module XYZ
  class CurrentSession
    extend Innate::StateAccessor
    state_accessor :user_object, :auth_filters, :access_time, :repoman_session_id

    def get_user_object()
      user_object
    end

    def set_repoman_session_id(session_id)
      self.repoman_session_id = session_id
    end

    def set_access_time(a_time)
      self.access_time = a_time
    end

    def last_access_time()
      self.access_time
    end

    def get_username()
      get_user_object()[:username]
    end

    def get_default_namespace()
      get_user_object()[:default_namespace]
    end

    def are_catalog_credentilas_set?()
      !(get_user_object().catalog_username.nil? || get_user_object().catalog_password.nil?)
    end

    def self.get_default_namespace()
      CurrentSession.new.get_default_namespace()
    end

    def self.get_username()
       CurrentSession.new.get_username()
    end

    def self.are_catalog_credentilas_set?()
      CurrentSession.new.are_catalog_credentilas_set?()
    end

    def self.catalog_credentials
      usr_obj = CurrentSession.new.get_user_object()
      { :username => usr_obj.catalog_username, :password => usr_obj.catalog_password }
    end

    def self.catalog_username
      catalog_credentials()[:username]
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
  class SessionTimeout < Error
  end
end
