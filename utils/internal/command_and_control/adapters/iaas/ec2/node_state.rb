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
module DTK; module CommandAndControlAdapter
  class Ec2
    module NodeStateClassMixin
      # assumed that node[:external_ref] and  node[:hostname_external_ref] are up to date
      def get_and_update_node_state!(node, attribute_names)
        ret = {}
        unless raw_state_info = raw_state_info!(node)
          return ret
        end

        # attribute_names in normalized form so need to convert
        change = nil
        attribute_names.each do |_normalized_attr_name|
          attribute_names.each do |attr_name|
            if AttributeMapping.respond_to?(attr_name)
              # TODO: if can legitimately have nil value then need to change logic
              if val = AttributeMapping.send(attr_name, ret, raw_state_info, node)
                ret[attr_name] = val
                change = true
              end
            end
          end
        end
        if change
          node.update(external_ref: node[:external_ref])
        end
        ret
      end

      module AttributeMapping
        def self.host_addresses_ipv4(_ret, raw_state_info, node)
          if ec2_public_address = raw_state_info[:dns_name] || raw_state_info[:public_ip_address]
            node[:external_ref][:ec2_public_address] = ec2_public_address
            dns = node[:external_ref][:dns_name] = ret_dns_value(raw_state_info, node)
            [dns]
          end
        end

        def self.fqdn(_ret, raw_state_info, node)
          if ec2_private_address = raw_state_info[:private_dns_name]
            if dns = ret_dns_value(raw_state_info, node)
              node[:external_ref][:private_dns_name] = { dns => ec2_private_address }
            end
          end
        end

        private

        def self.ret_dns_value(raw_state_info, node)
          node.persistent_dns() || node.elastic_ip() || raw_state_info[:dns_name] || raw_state_info[:public_ip_address]
        end
      end
      def ec2_public_address!(node)
        if raw_state_info = raw_state_info!(node)
          raw_state_info[:dns_name]
        end
      end

      def get_node_operational_status(node)
        state = get_node_state(node)
        op_status = state && state[:state]
        StateTranslation[op_status] || op_status
      end
      StateTranslation = {
        'pending' => 'starting',
        'shutting-down' => 'stopping'
      }

      private

      def get_node_state(node)
        if instance_id = get_instance_id_from_object(node)
          conn(node.get_target_iaas_credentials()).server_get(instance_id)
        end
      end

      def raw_state_info!(node)
        node[:raw_ec2_state_info] ||=  get_node_state(node)
      end

      def get_instance_id_from_object(node)
        node.update_object!(:external_ref)
        instance_id = (node[:external_ref] || {})[:instance_id]
        unless instance_id
          Log.error("get_node_state called when #{node[:display_name]} (#{node[:id]}) does not have instance id")
          return nil
        end
        instance_id
      end
    end
  end
end; end