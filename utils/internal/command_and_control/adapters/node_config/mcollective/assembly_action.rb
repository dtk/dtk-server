module DTK
  class CommandAndControlAdapter::Mcollective
    module AssemblyActionClassMixin
      def request__execute_action(agent,action,nodes,callbacks,params={})
        ret = nodes.inject({}){|h,n|h.merge(n[:id] => nil)}
        pbuilderids = nodes.map{|n|Node.pbuilderid(n)}
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = filter_single_fact("pbuilderid",value_pattern)
        async_context = {:expected_count => pbuilderids.size, :timeout => DefaultTimeout}
        #TODO: want this to be blocking call
        async_agent_call(agent.to_s,action.to_s,params,filter,callbacks,async_context)
      end
      DefaultTimeout = 3
      def parse_response__execute_action(nodes,msg)
        ret = Hash.new
        #TODO: conditionalize on status
        return ret.merge(:status => :notok) unless body = msg[:body]
        payload = body[:data]
        ret[:status] = (body[:statuscode] == 0 and payload and payload[:status] == :ok) ? :ok : :notok 
        ret[:pbuilderid] = payload && payload[:pbuilderid]
        ret[:data] = payload && payload[:data]
        ret
      end
    end
  end
end
