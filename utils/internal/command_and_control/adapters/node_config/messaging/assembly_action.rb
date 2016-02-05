#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  class CommandAndControlAdapter::Messaging
    module AssemblyActionClassMixin
      def request__execute_action(agent, action, nodes, callbacks, params = {})
        ret = nodes.inject({}) { |h, n| h.merge(n[:id] => nil) }
        pbuilderids = nodes.map { |n| Node.pbuilderid(n) }
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = filter_single_fact('pbuilderid', value_pattern)
        async_context = { expected_count: pbuilderids.size, timeout: DefaultTimeout }
        # TODO: want this to be blocking call
        async_agent_call(agent.to_s, action.to_s, params, filter, callbacks, async_context)
      end

      def request_execute_action_per_node(agent, action, node_hash, callbacks)
        node_hash.each do |node, param|
          request__execute_action_on_node(agent, action, [node], callbacks, param)
        end
      end

      def request__execute_action_on_node(agent, action, node, callbacks, params = {})
        ret = node.inject({}) { |h, n| h.merge(n => nil) }
        pbuilderids = []
        pbuilderids << params[:instance_id]
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = filter_single_fact('pbuilderid', value_pattern)
        async_context = { expected_count: pbuilderids.size, timeout: DefaultTimeout }
        # TODO: want this to be blocking call
        async_agent_call(agent.to_s, action.to_s, { components: params[:components], version_context: params[:version_context] }, filter, callbacks, async_context)
      end

      DefaultTimeout = 10

      def parse_response__execute_action(_nodes, msg)
        ret = {}
        # TODO: conditionalize on status
        return ret.merge(status: :notok) unless body = msg[:body]
        payload = body[:data]
        ret[:status] = (body[:statuscode] == 0 && payload && (payload[:status] == :ok || payload[:status] == :succeeded)) ? :ok : :notok
        ret[:pbuilderid] = payload && payload[:pbuilderid]

        # not every time we encapsulate our response under :data key
        ret[:data] = (payload && payload[:data]) ? payload[:data] : payload
        ret
      end
    end
  end
end