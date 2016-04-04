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
        r8_nested_require('node', 'image')
        r8_nested_require('node', 'violation')
        r8_nested_require('node', 'violation_processor')
        include ViolationProcessor::Mixin
        include ConnectedComponentMixin

        class ComponentType < Reified::ComponentType  
          module_name = 'ec2'
          Mapping = {
            :node => "#{module_name}::properties",
          }

        end
        Attributes = [:ami, :eth0_vpc_subnet_id, :instance_type, :kepair, :security_group_id, :security_group_name, :image_label]

        # opts can have keys
        # :dtk_node
        # :node_service_component
        # :reified_target
        # :no_reified_target - Boolean (default false) 
        def initialize(opts = {})
          node_service_component = opts[:node_service_component] || node_service_component(opts[:dtk_node])
          super(node_service_component.add_link_to_component!)
          @reified_target = opts[:no_reified_target] ? nil : ( opts[:reified_target] || reified_target_from_node(opts[:dtk_node]))
          # aws_conn gets dynamically set
          @aws_conn = nil
          # TODO: this will be eventually removed
          @external_ref = opts[:external_ref]
        end
        private :initialize

        def self.create_with_reified_target(dtk_node, reified_target, opts = {})
          new(opts.merge(reified_target: reified_target, dtk_node: dtk_node))
        end

        def self.create_from_service?(service, opts = {})
          node_service_components = service.matching_components?(ComponentType.node) || []
          Log.error("Unexpected that node_service_components.size > 1") if node_service_components.size > 1
          if  node_service_component = node_service_components.first 
            new(opts.merge(node_service_component: node_service_component, no_reified_target: true))
          end
        end

        def self.find_violations(service, params = {})
          ViolationProcessor.validate_and_fill_in_values(service, params)
        end

        def instance_type
          # TODO: remove @external_ref[:size] and default
          super || @external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size]  
        end

        def image
          @image ||= Image.validate_and_create_object(ami, self)
        end

        def security_group_names
          # TODO: not treating multiple security groups
          [security_group_name]
        end

        def security_group_ids
          # TODO: not treating multiple security groups
          [security_group_id]
        end

        def connected_component(conn_cmp_type)
          connected_component_aux(conn_cmp_type, @reified_target)
        end

        def region
          vpc_component.region
        end

        def aws_conn
          @aws_conn ||= get_aws_conn
        end

        def get_dtk_aug_attributes(*attribute_names)
          super(@reified_target, *attribute_names)
        end

        private

        def self.legal_attributes
          Attributes
        end
        
        def vpc_component
          connected_component(:vpc_subnet).connected_component(:vpc)
        end

        def get_vpc_component
          ret_singleton_or_raise_error('vpc', @reified_target.vpc_components)
        end

        def credentials_with_region
          vpc_component.credentials_with_region
        end

        def get_aws_conn
          Ec2.conn(credentials_with_region)
        end

        def node_service_component(dtk_node)
          fail Error, "Unexpected that dtk_node is nil" unless dtk_node

          filter = [:eq, :component_type, ComponentType.node.gsub(/::/,'__')]
          if dtk_component = dtk_node.get_components(filter: filter).first 
            Service::Component.new(dtk_component)
          else
            fail(Error, "Unexpected that no ec2 properties component on node")  
          end
        end

        def reified_target_from_node(dtk_node)
          fail(Error, "Unexpected that dtk_node is nil") unless dtk_node
          Target.new(Service::Target.create_from_node(dtk_node))
        end

      end
    end
  end
end; end




