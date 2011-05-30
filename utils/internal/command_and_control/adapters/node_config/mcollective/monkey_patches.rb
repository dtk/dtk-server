require 'mcollective'
######## Monkey patches 
module MCollective
  class Client
    #so discover can exit when get max number of item
    def discover(filter, timeout,opts={})
      begin
        reqid = sendreq("ping", "discovery", filter)
        @log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

        hosts = []
        Timeout.timeout(timeout) do
          while opts[:max_hosts_count].nil? or opts[:max_hosts_count] > hosts.size
            msg = receive(reqid)
            @log.debug("Got discovery reply from #{msg[:senderid]}")
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
    
    #so can in threads have multiple instances of stomp connection
    def initialize(configfile)
      @config = Config.instance
      @config.loadconfig(configfile) unless @config.configured
      @log = Log.instance
      @connection = PluginManager.new_instance("connector_plugin")

      @security = PluginManager["security_plugin"]
      @security.initiated_by = :client

      @options = nil

      @subscriptions = {}
      
      @connection.connect
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
        @log.warn("Ignoring a message that did not pass security validations")
        retry
      rescue MsgDoesNotMatchRequestID => e
        @log.debug("Ignoring a message for some other client")
        retry
      end
      msg
    end

    #modified so that a receiver can be passed in
    def r8_sendreq(msg, agent, filter = {}, opts = {})
      target = Util.make_target(agent, :command)
      reqid = opts[:request_id] || Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
pp [:sending_msg,reqid,msg]
      req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
      @log.debug("Sending request #{reqid} to #{target}")
      if opts[:receiver]
        opts[:receiver].add_request(reqid,opts[:receiver_context],{:agent => agent})
      else
        r8_add_subscription?(agent)
      end
      @connection.send(target, req)
      reqid
    end

    #add subscription is needed
    def r8_add_subscription?(agent)
      unless @subscriptions.include?(agent)
        topic = Util.make_target(agent, :reply)
        @log.debug("Subscribing to #{topic}")
        @connection.subscribe(topic)
        @subscriptions[agent] = 1
      end
    end

    #TODO: may deprecate below
    #monkey patch addition to avoid race condition TODO: if race condition not possible can remove
    def sendreq_part1(msg, agent, filter = {})
      target = Util.make_target(agent, :command)
      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
      req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
      @log.debug("Sending request #{reqid} to #{target}")
      unless @subscriptions.include?(agent)
        topic = Util.make_target(agent, :reply)
        @log.debug("Subscribing to #{topic}")
        @connection.subscribe(topic)
        @subscriptions[agent] = 1
      end
      [reqid,target,req]
    end
    def sendreq_part2(reqid,target,req)
      @connection.send(target, req)
      reqid
    end
    ########  
  end
  module PluginManager
    def self.new_instance(plugin)
      raise("No plugin #{plugin} defined") unless @plugins.include?(plugin)
      
      klass = @plugins[plugin][:class]
      eval("#{klass}.new")
    end
  end
end


