module DTK
  class AccountController < AuthController

  	def rest__set_password()
      password = ret_non_null_request_params(:new_password)
      user = CurrentSession.new.get_user_object()
      
      user.update_password(password)
      rest_ok_response username
    end

  end
end