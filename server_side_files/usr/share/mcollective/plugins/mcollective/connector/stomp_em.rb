require 'eventmachine'
module MCollective
  module Connector
        # Handles sending and receiving messages over the Stomp protocol
        #
        # This plugin supports version 1.1 or 1.1.6 and newer of the Stomp rubygem
        # the versions between those had multi threading issues.
        #
        # For all versions you can configure it as follows:
        #
        #    connector = stomp
        #    plugin.stomp.host = stomp.your.net
        #    plugin.stomp.port = 6163
        #    plugin.stomp.user = you
        #    plugin.stomp.password = secret
        #
        # For versions of ActiveMQ that supports message priorities
        # you can set a priority, this will cause a "priority" header
        # to be emitted if present:
        #
        #     plugin.stomp.priority = 4
        #
    class Stomp_em<Base
      #this is effectively a singleton, but not mixin in Singleton beacuse mcollective isstantiates with new
      #TODO: may look at making singleton and patching with making :new public, recognizing that will only be called once

      module StompClient
        include EM::Protocols::Stomp
        def initialize(*args)
          super(*args)
          #TODO: if cannot fidn user and log this shoudl be error
          conn_opts = (args.last.kind_of?(Hash))? args.last : {}
          @login = conn_opts[:login]
          @passcode = conn_opts[:passcode]
          @connected = false
        end

        def connection_completed
          connect :login => @login, :passcode => @passcode
        end

        def receive_msg msg
          if msg.command == "CONNECTED"
            @connected = true
          else
            Stomp_em.process(msg) 
          end
        end

        def is_connected?()
          @connected
        end
      end

      def initialize
        @config = Config.instance
        @subscriptions = []
        @connected = nil
        @connection = nil
      end

      def set_context(context)
        @@decode_context = context[:decode_context]
        @@multiplexer = context[:multiplexer]
      end

      def disconnect
        #TODO: need to write
      end

      # Connects to the Stomp middleware
      def connect
        if @connection
          Log.debug("Already connection, not re-initializing connection")
          return
        end
        begin
          host = nil
          port = nil
          user = nil
          password = nil
          @@base64 = false

          @@base64 = get_bool_option("stomp.base64", false)
          @@msgpriority = get_option("stomp.priority", 0).to_i

          # Maintain backward compat for older stomps
          host = get_env_or_option("STOMP_SERVER", "stomp.host")
          port = get_env_or_option("STOMP_PORT", "stomp.port", 6163).to_i
          user = get_env_or_option("STOMP_USER", "stomp.user")
          password = get_env_or_option("STOMP_PASSWORD", "stomp.password")

          #TODO: assume reactor is running already
          @connection = EM.connect host, port, StompClient, :login => user, :passcode => password
          Log.debug("Connecting to #{host}:#{port}")
         rescue Exception => e
          pp e.backtrace[0..5]
          raise("Could not connect to Stomp Server: #{e}")
        end
      end

      def wait_until_connected?
        return if @connected
        loop do 
          return if @connected = @connection.is_connected?
          sleep 1
        end
      end
    
    
      def self.process(msg)
        # STOMP puts the payload in the body variable, pass that
        # into the payload of MCollective::Request and discard all the
        # other headers etc that stomp provides
        raw_msg = 
          if @@base64
            Request.new(SSL.base64_decode(msg.body))
          else
            Request.new(msg.body)
          end     
        msg = @@decode_context.r8_decode_receive(raw_msg)
        @@multiplexer.process_response(msg,msg[:requestid])
      end

      #TODO: make automic subscribe_and_send because need subscribe to happen before send does
      # Subscribe to a topic or queue
      def subscribe(source)
        unless @subscriptions.include?(source)
          EM::defer do 
            Log.debug("Subscribing to #{source}")
            wait_until_connected?
            @connection.subscribe(source)
            @subscriptions << source
          end
        end
      end
      def subscribe_and_send(source,destination,body,params={})
        EM::defer do 
          wait_until_connected?
          unless @subscriptions.include?(source)
            Log.debug("Subscribing to #{source}")
            @connection.subscribe(source)
            @subscriptions << source
          end
          @connection.send(destination,body,params)
        end
      end

      # Subscribe to a topic or queue
      def unsubscribe(source)
        #TODO
      end
     private
      def get_env_or_option(env, opt, default=nil)
        return ENV[env] if ENV.include?(env)
        return @config.pluginconf[opt] if @config.pluginconf.include?(opt)
        return default if default

        raise("No #{env} environment or plugin.#{opt} configuration option given")
      end

      # looks for a config option, accepts an optional default
      #
      # raises an exception when it cant find a value anywhere
      def get_option(opt, default=nil)
        return @config.pluginconf[opt] if @config.pluginconf.include?(opt)
        return default if default

        raise("No plugin.#{opt} configuration option given")
      end

      # gets a boolean option from the config, supports y/n/true/false/1/0
      def get_bool_option(opt, default)
        return default unless @config.pluginconf.include?(opt)

        val = @config.pluginconf[opt]

        if val =~ /^1|yes|true/
          return true
        elsif val =~ /^0|no|false/
          return false
        else
          return default
        end
      end
    end
  end
end

# vi:tabstop=4:expandtab:ai
