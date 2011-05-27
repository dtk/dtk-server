module XYZ
  class CurrentSession
    extend Innate::StateAccessor
    state_accessor :user_object
    def get_user_object()
      user_object
    end
    def set_user_object(user_object)
      self.user_object = user_object
    end
  end
end
