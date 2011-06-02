require 'mcollective'
######## Monkey patches for version 1.2 
module MCollective
  class Client
    #so discover can exit when get max number of item
    def discover(filter, timeout,opts={})
      begin
        hosts = []
        Timeout.timeout(timeout) do
          reqid = sendreq("ping", "discovery", filter)
          Log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")
          while opts[:max_hosts_count].nil? or opts[:max_hosts_count] > hosts.size
            msg = receive(reqid)
            Log.debug("Got discovery reply from #{msg[:senderid]}")
            hosts << msg[:senderid]
          end
        end
       rescue Timeout::Error => e
        hosts.sort
       rescue Exception => e
        raise
      end
      hosts.sort
    end
    
    #so can pass nil argument and have it look for everything
    def receive(requestid = nil)
      msg = nil
      begin
        msg = @connection.receive
        msg = @security.decodemsg(msg)
        msg[:senderid] = Digest::MD5.hexdigest(msg[:senderid]) if ENV.include?("MCOLLECTIVE_ANON")
        #line patched added clause: requestid and
        raise(MsgDoesNotMatchRequestID, "Message reqid #{requestid} does not match our reqid #{msg[:requestid]}") if requestid and msg[:requestid] != requestid
      rescue SecurityValidationFailed => e
        Log.warn("Ignoring a message that did not pass security validations")
        retry
      rescue MsgDoesNotMatchRequestID => e
        Log.debug("Ignoring a message for some other client")
        retry
      end
      msg
    end

    #modified so that a receiver can be passed in
    def r8_sendreq(msg, agent, filter = {}, opts = {})
      target = Util.make_target(agent, :command, collective)
      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
pp [:sending_msg,reqid]
      # Security plugins now accept an agent and collective, ones written for <= 1.1.4 dont
      # but we still want to support them, try to call them in a compatible way if they
      # dont support the new arguments
      begin
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter, agent, collective)
       rescue ArgumentError
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
      end
      Log.debug("Sending request #{reqid} to #{target}")
      if opts[:receiver]
        opts[:receiver].add_request(reqid,opts[:receiver_context].merge(:agent => agent))
      else
        r8_add_subscription?(agent)
      end

      Timeout.timeout(2) do
        @connection.send(target, req)
      end

      reqid
    end

    #add subscription is needed
    def r8_add_subscription?(agent)
      unless @subscriptions.include?(agent)
        topic = Util.make_target(agent, :reply, collective)
        Log.debug("Subscribing to #{topic}")
        Util.subscribe(topic,@connection)
        @subscriptions[agent] = 1
      end
    end


    #TODO: write below interms of pieces above
    #monkey patched to use different subscribe
    def sendreq(msg, agent, filter = {})
      target = Util.make_target(agent, :command, collective)
      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")

      # Security plugins now accept an agent and collective, ones written for <= 1.1.4 dont
      # but we still want to support them, try to call them in a compatible way if they
      # dont support the new arguments
      begin
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter, agent, collective)
      rescue ArgumentError
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
      end
      
      Log.debug("Sending request #{reqid} to #{target}")

      unless @subscriptions.include?(agent)
        topic = Util.make_target(agent, :reply, collective)
        Log.debug("Subscribing to #{topic}")

        Util.subscribe(topic,@connection)
        @subscriptions[agent] = 1
      end

      Timeout.timeout(2) do
        @connection.send(target, req)
      end
      
      reqid
    end
  end

  #patch to reuse a passed in connection
  module Util
    def self.subscribe(topics,connection=nil)
      connection ||= PluginManager["connector_plugin"]
      if topics.is_a?(Array)
        topics.each do |topic|
          connection.subscribe(topic)
        end
      else
        connection.subscribe(topics)
      end
    end
  end

  #patch to allow multiple instances of client
  module Connector
    class Base
      def self.inherited(klass)
        # added :single_instance => false
        PluginManager << {:type => "connector_plugin", :class => klass.to_s, :single_instance => false}
      end
    end
  end
end


