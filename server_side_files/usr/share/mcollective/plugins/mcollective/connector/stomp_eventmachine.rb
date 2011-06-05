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
    class Stomp<Base
      module StompClient
        include EM::Protocols::Stomp
        def connection_completed
          Stomp.login 
        end

        def receive_msg msg
          Stomp.process(msg) unless msg.command == "CONNECTED"
        end
      end

      def initialize
        @config = Config.instance
        @subscriptions = []
        @connected = nil
      end

      def disconnect
      end

      # Connects to the Stomp middleware
      def connect
        if @connected
          Log.debug("Already connection, not re-initializing connection")
          return
        end
        begin
          host = nil
          port = nil
          user = nil
          password = nil
          @@base64 = get_bool_option("stomp.base64", false)
          @msgpriority = get_option("stomp.priority", 0).to_i

          # Maintain backward compat for older stomps
          host = get_env_or_option("STOMP_SERVER", "stomp.host")
          port = get_env_or_option("STOMP_PORT", "stomp.port", 6163).to_i
          @@user = get_env_or_option("STOMP_USER", "stomp.user")
          @@password = get_env_or_option("STOMP_PASSWORD", "stomp.password")

          #TODO: assume reactor is running already
          EM.connect host, port, StompClient
          @connected = true
          Log.debug("Connecting to #{host}:#{port}")
         rescue Exception => e
          raise("Could not connect to Stomp Server: #{e}")
        end
      end

      def self.login 
        connect :login => @@user, :passcode => @@password
      end

      def self.process(msg)
        # STOMP puts the payload in the body variable, pass that
        # into the payload of MCollective::Request and discard all the
        # other headers etc that stomp provides
        request = 
          if @@base64
            Request.new(SSL.base64_decode(msg.body))
          else
            Request.new(msg.body)
          end     
        pp request      
      end

      # Subscribe to a topic or queue
      def subscribe(source)
        unless @subscriptions.include?(source)
          Log.debug("Subscribing to #{source}")
          EM::Protocols::Stomp.subscribe(source)
          @subscriptions << source
        end
      end

      # Subscribe to a topic or queue
      def unsubscribe(source)
        Log.debug("Unsubscribing from #{source}")
        EM::Protocols::Stomp.unsubscribe(source)
        @subscriptions.delete(source)
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
