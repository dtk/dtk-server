
require File.expand_path('msg_bus_message', File.dirname(__FILE__))
# TBD: factor so have dynamically loaded adapters
require 'mq'
require 'bunny'

module XYZ
  # TBD: see if can do same by just doing an an include or extend AMQP
  class R8EventLoop
    class << self
      attr_reader :connection_opts
      def start(*args,&blk)
        @connection_opts = *args
        ::AMQP.start(*args,&blk)
      end

      def graceful_stop(msg=nil)
        ::AMQP.stop do
    Log.info(msg) if msg
         ::EM.stop
        end
      end

      def fork(num_workers,&block)
  ::AMQP.fork(num_workers,&block)
      end
    end
  end
end

module XYZ
  class MessageBusClient
    def initialize(connection_opts=nil)
      @connection_opts = connection_opts || XYZ::R8EventLoop.connection_opts || {}
      @native_clients = {}
    end

   def reset_client(type)
     close_clients_connections(type)
     @native_clients[type] = create_native_client(type,@connection_opts)
   end

   def close_clients_connections(type)
     raise Error.new("channel of type #{type} not treated") unless MessageBusClient.legal_channel_type?(type)
     return nil if @native_clients[type].nil?
     @native_clients[type].close()
   end

   # using bunny for exchanges and publish queues
   def exchange(name,opts={})
     R8ExchangeBunny.new(self,name,opts)
   end

   def publish_queue(name,opts={})
     R8QueueBunny.new(self,name,opts)
   end

   # using mq for subscribe queues
   def subscribe_queue(name,opts={})
     # TBD: here and analogously; only push in self and dynamically call native_client?(:mq)
     R8QueueMQ.new(self,name,opts)
   end

   def bind(queue_name,exchange_name,exchange_type,bind_opts={})
     exchange = exchange(exchange_name, type: exchange_type)
     publish_queue(queue_name).bind(exchange, bind_opts)
   end

   # returns native client, creates it if does not exist
   # TBD: should we fold reconnect logic into this fn?
   def native_client?(type)
     if @native_clients[type]
       return @native_clients[type]
     end
     @native_clients[type] = create_native_client(type,@connection_opts)
   end

   def self.generate_unique_id
     "uuid#{::Kernel.rand(999_999_999_999)}"
   end

    private

   def create_native_client(type,connection_opts={})
     case type
       when :mq
         ::MQ.new(::AMQP.connect(connection_opts))
       when :bunny
         native_client = ::Bunny.new(connection_opts)
         # TBD: asymetrical in that mq only staretd when in an event loop
         native_client.start()
         native_client
       else
       raise Error.new("client of type #{type} not treated")
     end
   end
   def self.legal_channel_type?(type)
    [:mq,:bunny].include?(type)
   end
  end
end

module XYZ
  module R8ExchangeQueueMixin
    # TBD: might take out ability to pass in uuid and hide this internally
    def publish_with_callback(msg_bus_msg_out,publish_opts_x={},&callback_block)
      uuid = publish_opts_x[:uuid] || MessageBusClient.generate_unique_id()
      reply_timeout = publish_opts_x[:reply_timeout]
      publish_opts = Aux::without_keys(publish_opts_x,[:uuid,:reply_timeout])
      raise Error.new("publish_with_callback whould not have opts[:reply_to] set") if publish_opts[:reply_to]
      publish_opts[:reply_to] = uuid
      response_queue = @client.subscribe_queue(uuid, auto_delete: true)

      publish_proc = proc {
        publish(msg_bus_msg_out,publish_opts)
        set_reply_timeout(reply_timeout,uuid) if reply_timeout
      }
      # publish put in callback to ensure executed after reply queue created
      if callback_block.arity == 1
        response_queue.subscribe(confirm: publish_proc) do |msg_bus_msg_in|
          @got_replies_from[uuid] = true
          callback_block.call(msg_bus_msg_in)
          response_queue.delete()
        end
      else #callback_block.arity == 2
        response_queue.subscribe(confirm: publish_proc) do |trans_info,msg_bus_msg_in|
          @got_replies_from[uuid] = true
          callback_block.call(trans_info,msg_bus_msg_in)
          response_queue.delete()
        end
      end
    end

    private

    def set_reply_timeout(reply_timeout,reply_queue_name)
      EM.add_timer(reply_timeout) {
        unless @got_replies_from[reply_queue_name]
         # TBD: msg is stubbed
         print "debug: sending cancled signal\n"
          msg_bus_msg_out = ProcessorMsg.create(msg_type: :time_out).marshal_to_message_bus_msg()
          timeout_queue = @client.publish_queue(reply_queue_name,passive: true)
    timeout_queue.publish(msg_bus_msg_out, task: :canceled)
        end
       }
    end
  end
end

module XYZ
  class R8Exchange
    attr_reader :native_exchange
    include R8ExchangeQueueMixin

    private

    def initialize(client)
     @client = client
     @got_replies_from = {}
    end
  end

  class R8ExchangeBunny < R8Exchange
    def initialize(client,name,opts)
      super(client)
      @name = name
      @opts = opts
      @native_exchange = client.native_client?(:bunny).exchange(name,opts)
    end

    def delete(opts={})
      @native_exchange.delete(opts)
    end
    # TBD: collapse with queue analog
    def publish(msg_bus_msg_out,publish_opts={})
      raw_body_and_publish_opts = msg_bus_msg_out.marshal_to_wire(publish_opts)
      begin
        @native_exchange.publish(*raw_body_and_publish_opts)
       rescue Bunny::ConnectionError
        begin
          @native_exchange = @client.reset_client(:bunny).exchange(@name,@opts)
          @native_exchange.publish(*raw_body_and_publish_opts)
         rescue Exception => e
          raise Error::AMQP.new()
        end
       rescue Exception => e
        raise Error::AMQP.new()
      end
    end
  end
end

module XYZ
  class R8Queue
   include R8ExchangeQueueMixin

    private

     def initialize(client)
       @client = client
       @got_replies_from = {}
     end
  end

  class R8QueueMQ < R8Queue
    def initialize(client,name,opts={})
      super(client)
      @mq_queue = client.native_client?(:mq).queue(name,opts)
    end

    def delete(opts={})
      @mq_queue.delete(opts)
    end

    def subscribe(opts={},&block)
       if block.arity == 1
         @mq_queue.subscribe(opts) do |raw_msg|
           block.call(MessageBusMsg.unmarshall_from_wire(raw_msg))
         end
       else #block.arity == 2
         @mq_queue.subscribe(opts) do |raw_header,raw_msg|
           block.call(*MessageBusMsg.unmarshall_from_wire2(raw_header,raw_msg))
         end
       end
    end
  end

  class R8QueueBunny < R8Queue
    def initialize(client,name,opts={})
      super(client)
      @name = name
      @opts = opts
      begin
        @native_queue = client.native_client?(:bunny).queue(name,opts)
       rescue Bunny::ForcedChannelCloseError
        @client.reset_client(:bunny)
        raise Error::AMQP::QueueDoesNotExist.new(name) if opts[:passive]
       rescue Exception
        raise Error::AMQP.new()
      end
    end

    def delete(opts={})
      @native_queue.delete(opts)
    end

    # TBD: may call form publish_aux that takes num of retries
    def publish(msg_bus_msg_out,publish_opts={})
      raw_body_and_publish_opts = msg_bus_msg_out.marshal_to_wire(publish_opts)
      begin
        @native_queue.publish(*raw_body_and_publish_opts)
       rescue Bunny::ConnectionError
        begin
          @native_queue = @client.reset_client(:bunny).queue(@name,@opts)
          @native_queue.publish(*raw_body_and_publish_opts)
         rescue Exception
          raise Error::AMQP.new()
        end
       rescue Exception
        raise Error::AMQP.new()
      end
    end

    def bind(exchange,opts={})
      raise Error.new("exchange is wrong type") unless exchange.is_a?(R8ExchangeBunny)
      @native_queue.bind(exchange.native_exchange,opts)
    end
  end
end

# TBD: not sure if needed now because explicitly seting connection within fork
# monkey patch that is used when want to call AMPQ.fork and set params like :host
# TBD: better wrap the classes to hide MQ and posibly to wrap ops like subscribe and publish
AMQP.class_eval do
  def self.set_settings(opts={})
    settings #to set @settings with defaults
    opts.each{|k,v| @settings[k] = v}
  end
end
