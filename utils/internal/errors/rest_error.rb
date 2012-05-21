module XYZ
  class RestError  
    def self.create(internal_error)
      if internal_error.kind_of?(::NoMethodError)
        NotFound.new(internal_error)
      else
        new(internal_error)
      end
    end
    def initialize(internal_error)
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
        super.merge(:internal => true)
      end 
    end
    class Usage < RestError
    end
    class NotFound < Usage
      def initilize(internal_error)
        super
        @code = :not_found
      end
    end
  end
end
