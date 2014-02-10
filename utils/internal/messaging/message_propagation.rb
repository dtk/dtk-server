require File.expand_path('amqp_clients_wrapper', File.dirname(__FILE__))
require File.expand_path('worker_tasks', File.dirname(__FILE__))
require File.expand_path('processor_msg', File.dirname(__FILE__))
module XYZ
  class MessageProcessor
    def process_message(hash_message)
      raise Error::NotImplemented.new("process_message for #{self.class.to_s}\n")
    end
    def object_id(msg)
      raise Error::NotImplemented.new("object_id for #{self.class.to_s}\n")
    end
  end

  #A worker gets assigned a set of message processors
  class Worker
    #if create two workers with same name they need to have same processors
    #TBD: direct queues are supposed to have less cpu demand so consider switch; question is that would create many exchanges; is that much overhead?
    def initialize(unique_name="default")
      @unique_name = unique_name
      @processors = {}
      @msg_bus_client = nil
    end
    def add_processor(processor)
      @processors[processor.object_id] ||= processor 
    end
    #TBD: either rename to reflect that this is just attribute queues or generalize
    def self.bind_queues(host_addr,object_ids_assigns)
      R8EventLoop.start(:host => host_addr) do
         @msg_bus_client = MessageBusClient.new()
         object_ids_assigns.each{|object_id,unique_name|
           topic_name = MessageBusMsgOut.topic(:attribute)
           key = MessageBusMsgOut.key(object_id,:attribute)
           @msg_bus_client.bind(unique_name,topic_name,:topic,:key => key)    
         }
         R8EventLoop::graceful_stop()
       end
    end

    def start(host_addr,opts={})
      #TBD: check if best practice to put signal def in fn
      Signal.trap('INT') { R8EventLoop.graceful_stop("stopped worker loop")}
      Signal.trap('TERM'){ R8EventLoop.graceful_stop("stopped worker loop")}

      R8EventLoop.start(opts.merge(:host => host_addr)) do
        @msg_bus_client = MessageBusClient.new()
        @msg_bus_client.subscribe_queue(@unique_name).subscribe do |trans_info,msg_bus_msg_in|
          Log.info "----------------\n"
          Log.info_pp [:received, trans_info,msg_bus_msg_in]
          proc_msg = ProcessorMsg.new(msg_bus_msg_in.parse())

	  object_id = proc_msg.target_object_id
          next if @processors[object_id].nil? #TBD: should this be an error?
          #TBD: might refactor to use more standard form like dispatching to nanite or controller like actions; 
          task_set = @processors[object_id].process_message(proc_msg)
          task_set.determine_local_and_remote_tasks!(self)
          if trans_info[:reply_to]
            task_set.add_reply_to_info(trans_info[:reply_to],@msg_bus_client)
          end
          #TBD: this will be generalized to take a task of type basic and then choose if local or remote and add needed info
          task_set.add_routing_info :msg_bus_client => @msg_bus_client

          task_set.execute()
        end

        #to prime the processor caches
        @processors.each_key do |object_id|
          proc_msg = ProcessorMsg.create(
            {:msg_type => :propagate_asserted_value,
            :target_object_id => object_id})
	  topic_name = proc_msg.topic()
	  key = proc_msg.key()
          msg_bus_msg = proc_msg.marshal_to_message_bus_msg()
          exchange = @msg_bus_client.exchange(topic_name, :type => :topic)
	  exchange.publish(msg_bus_msg,:key => key)
        end
      end
    end
  end
end

