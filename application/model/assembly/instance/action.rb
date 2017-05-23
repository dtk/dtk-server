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
  class Assembly::Instance
    module Action
      require_relative('action/ssh_access')
      class GetLog < ActionResultsQueue
        private

        def action_hash
          { agent: :tail, method: :get_log }
        end
      end
      class Grep < ActionResultsQueue
        private

        def action_hash
          { agent: :tail, method: :grep }
        end
      end

      class GetPs < ActionResultsQueue
        private

        def action_hash
          { agent: :ps, method: :get_ps }
          #{ agent: :system_agent, method: :get_ps }
        end

        def process_data!(data, node_info)
          Result.new(node_info[:display_name], data.map { |r| node_info.merge(r) })
        end

        # def messaging_protocol
        #   'stomp'
        # end
      end

      class GetArbiter < ActionResultsQueue
        def action_hash
          { agent: :action, method: :run_command }
        end

        def process_data!(data, node_info)
          Result.new(node_info[:display_name], data)
        end

        def messaging_protocol
          'stomp'
        end
      end

      class ActionAgent < ActionResultsQueue
        def action_hash
          { agent: :action_agent, method: :run_command }
        end
      end

      class GetNetstats < ActionResultsQueue
        private

        def action_hash
          { agent: :netstat, method: :get_tcp_udp }
          # { agent: :system_agent, method: :get_tcp_udp }
        end

        def process_data!(data, node_info)
          ndx_ret = {}
          data.each do |r|
            next unless r[:state] == 'LISTEN' || r[:protocol] == 'udp'
            if r[:local] =~ /(^.+):([0-9]+$)/
              address = Regexp.last_match(1)
              port = Regexp.last_match(2).to_i
              next unless address =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|::/
              ndx_ret["#{address}_#{port}"] ||= {
                port: port,
                local_address: address,
                protocol: r[:protocol]
              }
              end
          end
          Result.new(node_info[:display_name], ndx_ret.values)
        end

        # def messaging_protocol
        #   'stomp'
        # end
      end
    end
  end
end
