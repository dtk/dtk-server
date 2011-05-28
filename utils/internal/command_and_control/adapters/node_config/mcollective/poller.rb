#TODO: generalzie to sending all requests
module XYZ
  module CommandAndControl
    class McollectivePoller
      def initialize(client,listener)
        @client = client
        @listener = listener
      end
     private
      def sendreq_agent(agent,action,data,filter={})
        msg = new_request(agent,action,data)
        sendreq(msg, msg[:agent], filter)
      end
      def sendreq_discover(filter={})
        sendreq("ping", "discovery",filter)
      end
      def sendreq(msg,agent,filter={})
        reqid,target,req = @client.sendreq_part1(msg,agent,filter)
        @listener.add_request_id(reqid)
        @client.sendreq_part2(reqid,target,req)
      end

      #TODO: wrote own so can insert agent
      def new_request(agent,action, data)
        callerid = PluginManager["security_plugin"].callerid
        {:agent  => agent,
          :action => action,
          :caller => callerid,
          :data   => data}
      end
    end
    class McollectivePollerNodeReady < McollectivePoller
      def send(filter={})
         sendreq_discover(filter)
      end
    end
  end
end

#monkey patch to avoid race condition TODO: if race condition not possible can remove
module MCollective
  class Client
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
  end
end
