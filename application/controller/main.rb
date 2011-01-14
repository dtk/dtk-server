module XYZ
  class MainController < Controller
    def login
      @title = "Login"
      redirect_referer if logged_in?
      #cred = request.subset(:login, :password)
      cred = {:login => "rich"}
      user_login(cred)
      redirect DatacenterController.r(:list)
    end

    def register(explicit_hash=nil,opts={})
      hash = explicit_hash || request.params.dup
      save(hash)
      @title = "Register for an account"
      flash[:message] = 'Account created, feel free to login below'
      redirect DatacenterController.r(:list)
=begin
    if request.post?
      @user = ::User.new
      @user[:email] = request[:email]
      @user.password = request[:password]
      @user.password_confirmation = request[:password_confirmation]
      @user.salt = Digest::SHA1.hexdigest("--#{Time.now.to_f}--#{user.email}--") 
    
      if @user.save
        flash[:message] = 'Account created, feel free to login below'
        #TODO: stub to initial page
        redirect MainController.r(:index)
      end
=end
    end
##### end of user fns
  end
end

