module XYZ
  module CreateThread

    def self.defer_with_session(user_object, &block)
      Ramaze::defer(&wrap(user_object, &block))
    end

    private

    def self.defer(&block)
      Ramaze::defer(&wrap(&block))
    end

    # wrap() - Added this part of code so if thread fails we will know imedietly. Helps with development,
    # in case there is some internal logic that expects some thread to fail error messages can be
    # ignored or this call

    def self.wrap(user_object=nil, &block)
      return lambda do
        begin
          # this part of code sets session information to make sure that newly created thread keeps its session
          # this was necessery due to concurency issues
          if user_object
            Thread.current[:user_object]    = user_object
            # Thread.current[:session][:USER] = ::DTK::User::create_user_session_hash(user_object) unless Thread.current[:session]
            Ramaze::Current.session[:USER]  = ::DTK::User::create_user_session_hash(user_object)
          end

          # yield original block
          yield

          # end
        rescue Exception => e
          Log.error_pp(["ERROR IN THREAD",e.message,e.backtrace])
        end
      end
    end

  end
end
