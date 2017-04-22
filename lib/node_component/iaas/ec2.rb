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
  class NodeComponent::IAAS
    class Ec2 < self
      require_relative('ec2/client_token')
      require_relative('ec2/tag')
      require_relative('ec2/instance')
      require_relative('ec2/group')
      
      def set_special_attributes
        update_attribute!(:dtk_agent_info, dtk_agent_info)
        update_attribute!(:tags, tags)
        HostAttributes.link_to_node(self)
      end

      DYNAMIC_SPECIAL_ATTRIBUTES = {
        :client_token => {
          :test => lambda { |ec2_node_component| ec2_node_component.generate_new_client_token? },
          :value => lambda { |_ec2_node_component| ClientToken.generate }
        }
      }
      # returns [is_special_value, special_value] where if first is false then second should be ignored
      def update_if_dynamic_special_attribute!(attribute)
        ret = [false, nil]
        attribute_symbol = attribute.display_name.to_sym
        unless special_value_info = DYNAMIC_SPECIAL_ATTRIBUTES[attribute_symbol]
          return ret
        end
        unless special_value_info[:test].call(self)
          return ret
        end
        value = special_value_info[:value].call(self)
        update_attribute!(attribute_symbol, value)
        [true, value]
      end
      
      def generate_new_client_token?
        fail Error::NoMethodForConcreteClass.new(self.class)
      end
      
      private

      def dtk_agent_info
        template_bindings = {
          node_config_server_host: CommandAndControl.node_config_server_host,
          git_server_url: RepoManager.repo_url,
          git_server_dns: RepoManager.repo_server_dns,
          fingerprint: RepoManager.repo_server_ssh_rsa_fingerprint
        }
        {         
          install_script: CommandAndControl.node_config_adapter_install_script(node, template_bindings),
          cloud_config: CommandAndControl.node_config_adapter_cloud_config_options(node, template_bindings)
        }
      end
      
      def tags
        (attribute_value(:tags) || {}).merge('Name' => Tag.name(self))
      end
    end
  end
end
