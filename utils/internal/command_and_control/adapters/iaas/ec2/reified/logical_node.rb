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
  class CommandAndControlAdapter::Ec2
    module Reified
      class LogicalNode < DTK::Service::Reified::Component::WithServiceComponent
        include ConnectedComponentMixin
        # opts can have keys
        # :reified_target
        def initialize(dtk_node, opts = {})
          reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
          super(dtk_component_ec2_properties(dtk_node, reified_target.target_service))
          @dtk_node = dtk_node
          @reified_target = reified_target
        end

        def connected_component(conn_cmp_type)
          connected_component_aux(conn_cmp_type, @reified_target)
        end
        private

        Attributes = [:ami, :eth0_vpc_subnet_id, :instance_type, :kepair, :security_group_id]
        def self.legal_attributes
          Attributes
        end

        Ec2PropertiesInternalType = 'ec2__properties'
        ComponentTypeFilter = {filter: [:eq, :component_type, Ec2PropertiesInternalType]}

        def dtk_component_ec2_properties(dtk_node, target_service)
          ret = 
            if dtk_component = dtk_node.get_components(ComponentTypeFilter).first 
              Service::Component.new(dtk_component).add_link_to_component!(target_service)
            end
          ret || fail(Error, "Unexpected that no ec2 properties component on node")
        end
        
        # TODO: below should be replaced
        public

        def credentials_with_region
          use_and_set_attribute_cache(:credentials_with_region) { get_credentials_with_region }
        end
        
        def region
          (credentials_with_region || {})[:region]
        end

        def vpc_component
          connected_component(:vpc_subnet).connected_component(:vpc)
          # use_and_set_connected_component_cache(:vpc) { get_vpc_component }
        end

        def get_vpc_component
          ret_singleton_or_raise_error('vpc', @reified_target.vpc_components)
        end

        def get_credentials_with_region
          vpc_component.credentials_with_region
        end

        def raise_error_if_empty(type, reified_components)
          if reified_components.empty?
            fail ErrorUsage, "No '#{type}' components in the target service"
          end
        end

        # Returns the reified_component if singleton, otherwise raises error
        def ret_singleton_or_raise_error(type, reified_components)
          raise_error_if_empty(type, reified_components)
          if reified_components.size > 2
            # TODO: need to use link from node for his
            fail Error, "Not implemented: A target service with multiple '#{type}' components"
          end
          reified_components.first
        end

      end
    end
  end
end

=begin
old
module DTK
  class CommandAndControlAdapter::Ec2
    module Reified
      class LogicalNode < DTK::Service::Reified::Component::WithServiceComponent
        # opts can have keys
        # :reified_target
        def initialize(dtk_node, opts = {})
          
          super()
          @dtk_node       = dtk_node
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
        end


        def security_groups
          use_and_set_attribute_cache(:security_groups) { get_security_groups }
        end

        private

        def get_security_groups
          # TODO: if multiple security groups find ones associated with node
          # Below finds all associated with the vpc that the security group is connected to
          matching_sg_reified_components = @reified_target.get_matching_security_groups(vpc_component.id)
          raise_error_if_empty('security group',matching_sg_reified_components)
          matching_sg_reified_components.map(&:security_group_struct)
        end


      end
    end
  end
end
=end

