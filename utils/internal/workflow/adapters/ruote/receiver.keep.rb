module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        #TODO: might put operations on @listener in mutex
        #TODO: put operations on workitem store and poller store in mutex
        @listener = listener
        @request_ids = Array.new

        @workitem_store = Hash.new
        @timer_store = Hash.new
        @poller_store = Hash.new

        common_init()
      end
      def add_request(request_id,context,opts={})
        @workitem_store[request_id] = context.workitem
        if opts[:from_poller]
          @poller_store[request_id] = opts[:from_poller]
        end
        @listener.add_request_id(request_id,context.opts.merge(opts))
        start()
        timeout = opts[:timeout]||DefaultTimeout
        @timer_store[request_id] = R8EM.add_timer(timeout){process_request_timeout(request_id)}
      end
     private
      DefaultTimeout = 60

      def loop
        while not is_stopped?()
          wait_and_process_message()
        end
      end

      def process_request_timeout(request_id)
        pp [:timeout, request_id]
        cancel_timer(request_id, :is_expired => true)
        if poller_info = @poller_store.delete(request_id)
          poller_info[:poller].remove_item(poller_info[:key])
        end
        @listener.remove_request_id(request_id)
        workitem = @workitem_store.delete(request_id)
        stop() if @workitem_store.empty?
        if workitem
          workitem.fields["result"] = {"status" => "timeout"} 
          reply_to_engine(workitem)
        end
      end
      def wait_and_process_message()
        msg,request_id = @listener.process_event()
        cancel_timer(request_id)
        if poller_info = @poller_store.delete(request_id)
          poller_info[:poller].remove_item(poller_info[:key])
        end
        workitem = @workitem_store.delete(request_id)
        @workitem_store.empty?
        if workitem
          workitem.fields["result"] = msg[:body]
          reply_to_engine(workitem)
        else
          Log.error("could not find a workitem for request_id #{request_id.to_s}")
        end
      end

      def cancel_timer(request_id,opts={})
        timer = @timer_store.delete(request_id)
        unless opts[:is_expired]
          R8EM.cancel_timer(timer) if timer
        end
      end
    end

    class RuoteReceiverContext < ReceiverContext
      attr_reader :workitem, :opts
      def initialize(workitem,opts={})
        @workitem = workitem
        @opts = opts
      end
    end
  end
end
