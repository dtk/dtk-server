module XYZ
  module CommandAndControl
    class McollectivePoller
      def initialize(client)
        @client = client
      end
     private
      def sendreq(agent,action,data,filter)
        msg = new_request(agent,action,data)
        @client.sendreq(msg, msg[:agent], filter)
      end
      def sendreq_discover(filter)
        @client.sendreq("ping", "discovery", filter)
      end
      #TODO: wrote own so can insert agent
      def new_request(agent,action, data)
        callerid = PluginManager["security_plugin"].callerid
        {:agent  => @agent,
          :action => action,
          :caller => callerid,
          :data   => data}
      end
    end
    class McollectivePollerNodeReady < McollectivePoller
      def send(filter)
         sendreq_discover(filter)
      end
    end
  end
end


