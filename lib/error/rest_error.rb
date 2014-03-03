module DTK
  class RestError  
    def self.create(err)
      if RestUsageError.match?(err)
        RestUsageError.new(err)
      elsif NotFound.match?(err)
        NotFound.new(err)
      else
        Internal.new(err)
      end
    end
    def initialize(err)
      @code = nil
      @message = nil
    end
    def hash_form()
      {:code => code||:error, :message => message||''}
    end 
    private
     attr_reader :code, :message
    public
    #its either its a usage or and internal (application error) bug
    class Internal < RestError
      def hash_form()
        ret = super.merge(:internal => true)
        ret.merge!(:backtrace => @backtrace) if @backtrace
        ret
      end 
     private
      def initialize(err)
        super
        # @message = "#{err.to_s} (#{err.backtrace.first})"
        # Do not see value of exposing single line to client, we will still need logs to trace the error
        @message = err.to_s
        if (R8::Config[:error_handling]||{})[:backtrace] 
          @backtrace = err.backtrace
        end
      end
    end
    class RestUsageError < RestError
      def initialize(err)
        super
        @message = err.to_s
      end
      def self.match?(err)
        err.kind_of?(ErrorUsage)
      end
    end
    class NotFound < RestUsageError
      def self.match?(err)
        err.kind_of?(::NoMethodError) and is_controller_method(err)
      end
      def initialize(err)
        super
        @code = :not_found
        @message = "'#{err.name}' was not found"
      end
     private
      def self.is_controller_method(err)
        err.to_s =~ /#<XYZ::.+Controller:/
      end
    end
  end
end
