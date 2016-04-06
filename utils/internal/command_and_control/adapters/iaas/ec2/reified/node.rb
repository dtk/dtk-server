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
    module Reified
      class Node < DTK::Service::Reified::Component
        r8_nested_require('node', 'violation')
        r8_nested_require('node', 'violation_processor')
        r8_nested_require('node', 'with_aws_conn')

        include ViolationProcessor::Mixin
        include ConnectedComponentMixin

        class ComponentType < Reified::ComponentType  
          module_name = 'ec2'
          Mapping = {
            :node => "#{module_name}::properties",
          }

        end
        Attributes = [:ami, :eth0_vpc_subnet_id, :instance_type, :kepair, :security_group_id, :security_group_name, :vpc_images, :region, :os_type, :size, :image_label]

        # opts can have keys
        # :service
        # :dtk_node_or_node_group - this is anode or node group and not a node group member
        # :node_service_component
        # :external_ref
        def initialize(opts = {})
          node_service_component = opts[:node_service_component] || node_service_component(opts[:dtk_node_or_node_group])
          super(node_service_component.add_link_to_component!)
          @service = opts[:service]
          
          # TODO: this will be eventually removed
          @external_ref = opts[:external_ref]
        end
        private :initialize

        def self.create_with_aws_conn(dtk_node_or_node_group_member, reified_target, opts = {})
          # if dtk_node_or_node_group_member is a node_group_member we want is node group
          # otherwise it is a node and it is returned
          dtk_node_or_ngm = dtk_node_or_node_group_member
          dtk_node_or_node_group = is_node_group_member?(dtk_node_or_ngm) || dtk_node_or_ngm
          WithAwsConn.new(opts.merge(reified_target: reified_target, dtk_node_or_node_group: dtk_node_or_node_group))
        end

        def self.create_nodes_from_service(service, opts = {})
          (service.matching_components?(ComponentType.node) || []).map do |node_service_component|
            new(opts.merge(service: service, node_service_component: node_service_component, no_reified_target: true))
          end
        end

        def self.find_violations(service, params = {})
          ViolationProcessor.validate_and_fill_in_values(service, params)
        end

        def security_group_names
          # TODO: not treating multiple security groups
          [security_group_name]
        end

        def security_group_ids
          # TODO: not treating multiple security groups
          [security_group_id]
        end

        private

        def self.legal_attributes
          Attributes
        end
        
        def node_service_component(dtk_node_or_node_group)
          fail Error, "Unexpected that dtk_node_or_node_group is nil" unless dtk_node_or_node_group

          filter = [:eq, :component_type, ComponentType.node.gsub(/::/,'__')]
          if dtk_component = dtk_node_or_node_group.get_components(filter: filter).first 
            Service::Component.new(dtk_component)
          else
            fail(Error, "Unexpected that no ec2 properties component on node")  
          end
        end

        #returns a node group object if dtk_node_or_node_group_member is a node group member
        def self.is_node_group_member?(dtk_node_or_node_group_member)
          dtk_node_or_ngm = dtk_node_or_node_group_member
          sp_hash = {
            cols: [:id, :display_name, :group_id, :node_members]
          }
          node_id = dtk_node_or_ngm.id
          ret = Model.get_objs(dtk_node_or_ngm.model_handle, sp_hash).select { |ng| ng[:node_member].id == node_id }
          if ret.size > 1
            fail Error, "TODO: DTK-2526: Not supporting two or more more service that have common nodes"
          end
          ret.first
        end
      end
    end
  end
end; end




