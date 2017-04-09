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
      
      def set_special_attributes
        update_attribute!(:dtk_agent_info, dtk_agent_info)
        update_attribute!(:tags, tags)
        update_attribute!(:client_token, ClientToken.generate)
        link_host_attributes_to_node
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
        (attribute_value?(:tags) || {}).merge('Name' => Tag.name(self))
      end
    end
  end
end
