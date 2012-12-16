module DTK
  class AsyncResponse
    include ::EventMachine::Deferrable
    def self.create(async_callback,content_type,response_procs,&blk)
      deferred_body = new(response_procs)
      async_callback.call [200, {'Content-Type' => content_type},deferred_body]
      CreateThread.defer do
        begin
          blk.call(deferred_body)
        rescue => e
          deferred_body.rest_notok_response(e)
        end
      end
      throw :async
    end

    def rest_ok_response(data)
      push_data(@response_procs[:ok].call(data))
      signal_eos()
    end
    def rest_notok_response(data)
      push_data(@response_procs[:notok].call(data))
      signal_eos() 
    end

    #needed by rack/thin
    def each(&blk)
      @body_callback = blk
    end

   private
    def initialize(response_procs)
      @response_procs = response_procs
      super()
    end

    def push_data(data)
      @body_callback.call data
    end

    def signal_eos()
      succeed()
    end
  end
end
