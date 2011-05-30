#TODO: generalzie to sending all requests
module XYZ
  module CommandAndControlAdapter
    class McollectivePoller
      def initialize(client,listener)
        @client = client
        @listener = listener
      end
     private
      def sendreq_agent(agent,action,data,filter={})
        msg = Mcollective.new_request(agent,action,data)
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

    end
    class McollectivePollerNodeReady < McollectivePoller
      def send(filter={})
         sendreq_discover(filter)
      end
    end
  end
end

