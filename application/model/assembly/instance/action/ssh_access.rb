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
      class SSHAccess < ActionResultsQueue
        def initialize(opts = {})
          super()
          @agent_action = opts[:agent_action]
        end

        def action_hash
          { agent: :ssh_agent, method: @agent_action }
        end
        #TODO: write this in terms of its parent ActionResultsQueue#initiate or have arent method in terms of reusable fragments
        def initiate(nodes, params, _opts = {})
          indexes = nodes.map { |r| r[:id] }
          set_indexes!(indexes)
          ndx_pbuilderid_to_node_info =  nodes.inject({}) do |h, n|
            h.merge(n.pbuilderid => { id: n[:id], display_name: n.assembly_node_print_form() })
          end
          callbacks = {
            on_msg_received: proc do |msg|

              response = CommandAndControl.parse_response__execute_action(nodes, msg)
              if response && response[:pbuilderid] && response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]

                unless response[:data][:error]
                  component_type = :authorized_ssh_public_key
                  attr_hash = {
                    linux_user: params[:system_user],
                    key_name: params[:rsa_pub_name],
                    key_content: params[:rsa_pub_key]
                  }
                  node = nodes.find { |n| n[:id] == node_info[:id] }

                  if (@agent_action == :grant_access)
                    Component::Instance::Interpreted.create_or_update?(node, component_type, attr_hash)
                  else
                    Component::Instance::Interpreted.delete(node, component_type, attr_hash)
                  end
                end

                push(node_info[:display_name], response[:data])
              else
                Log.error("Agent '#{msg[:senderagent]}' error, Code: #{msg[:body][:statuscode]} - #{msg[:body][:statusmsg]}")
              end

            end
          }
          CommandAndControl.request__execute_action(:ssh_agent, @agent_action, nodes, callbacks, params)
        end
      end
    end
  end
end