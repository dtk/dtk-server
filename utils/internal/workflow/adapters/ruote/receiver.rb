module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        #TODO: might put operations on @listener in mutex
        @listener = listener
        @callbacks = Hash.new
        @lock = Mutex.new
        common_init()
      end

      def add_request(request_id,context,opts={})
        @listener.add_request_id(request_id,context.opts.merge(opts))

        callback_type = 
          if opts[:from_poller] then :poller
          else :workitem
        end
        callback = 
          case callback_type
            when :poller then callback_poller(request_id,context,opts)
            when :workitem then callback_workitem(request_id,context,opts)
        end

        timeout = opts[:timeout]||DefaultTimeout
        add_callback(request_id,callback,timeout)
        start?()
      end
     private
      DefaultTimeout = 60

      def callback_poller(request_id,context,opts)
        CallbackPoller.new(opts[:from_poller])
      end 

      def callback_workitem(request_id,context,opts)
        CallbackWorkitem.new(:workitem => context.workitem)
      end 

      def add_callback(request_id,callback_x,timeout=nil)
        callback = timeout ? 
          callback_x.merge(:timer => R8EM.add_timer(timeout){process_request_timeout(request_id)}) :
          callback_x
        @lock.synchronize{@callbacks[request_id] = callback}
      end

      def get_and_remove_callback(request_id)
        ret = nil
        @lock.synchronize{ret = @callbacks.delete(request_id)}
        ret
      end

      def loop
        while not is_stopped?()
          wait_and_process_message()
        end
      end

      def wait_and_process_message()
        msg,request_id = @listener.process_event()
        callback = get_and_remove_callback(request_id)
        callback.process_msg(msg,request_id,self)
      end

      def process_request_timeout(request_id)
        pp [:timeout, request_id]
        @listener.remove_request_id(request_id)
        callback = get_and_remove_callback(request_id)
        callback.process_timeout(request_id,self)
      end

      class Callback < HashObject
        def cancel_timer(request_id,opts={})
          timer = self[:timer]
          unless opts[:is_expired]
            R8EM.cancel_timer(timer) if timer
          end
        end
      end

      class CallbackWorkitem < Callback
        def process_msg(msg,request_id,receiver)
          cancel_timer(request_id)
          workitem = self[:workitem]
          if workitem
            workitem.fields["result"] = msg[:body]
            receiver.reply_to_engine(workitem)
          else
            Log.error("could not find a workitem for request_id #{request_id.to_s}")
          end
        end
        def process_timeout(request_id,receiver)
          workitem = self[:workitem]
          if workitem
            workitem.fields["result"] = {"status" => "timeout"} 
            receiver.reply_to_engine(workitem)
          else
            Log.error("could not find a workitem for request_id #{request_id.to_s}")
          end
        end
      end
      class CallbackPoller < Callback
        #TODO: write ruotine
        #action for process timeout poller_info[:poller].remove_item(poller_info[:key])
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

