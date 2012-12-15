module Ramaze::Helper
  module RestAsync
    def rest_deferred_response(&blk)
      deferred_body = initiate_stream()
      ::DTK::CreateThread.defer do
        yield deferred_body
      end
      throw :async
    end
   private
    def initiate_stream()
      ok_response_proc = lambda{|data|JSON.pretty_generate(rest_ok_response(data))} 
      notok_response_proc = lambda{|data|JSON.pretty_generate(rest_notok_response(data))} 
      deferred_body = Deferred::Body.new(ok_response_proc,notok_response_proc)
      request.env['async.callback'].call [200, {'Content-Type' => 'text/html'},deferred_body]
      deferred_body
    end
    
    module Deferred
      class Body 
        include ::EventMachine::Deferrable
        def initialize(ok_response_proc,notok_response_proc)
          @ok_response_proc = ok_response_proc
          @notok_response_proc = notok_response_proc
          super()
        end
        def rest_ok_response(data)
          push_data(@ok_response_proc.call(data))
          signal_eos()
        end
        def rest_notok_response(data)
          push_data(@notok_response_proc.call(data))
          signal_eos() 
        end

        #needed by rack/thin
        def each(&blk)
          @body_callback = blk
        end

       private
        def push_data(data)
          @body_callback.call data
        end

        def signal_eos()
          succeed()
        end
      end
    end
  end
end
