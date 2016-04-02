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
        Attributes = [:ami, :eth0_vpc_subnet_id, :instance_type, :kepair, :security_group_id, :security_group_name]

        # opts can have keys
        # :reified_target
        def initialize(dtk_node, opts = {})
          super(dtk_component_ec2_properties(dtk_node))
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
          @dtk_node       = dtk_node
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

        def credentials_with_region
          use_and_set_attribute_cache(:credentials_with_region) { get_credentials_with_region }
        end

        def region
          (credentials_with_region || {})[:region]
        end

        private

        def self.legal_attributes
          Attributes
        end

        Ec2PropertiesInternalType = 'ec2__properties'
        ComponentTypeFilter = {filter: [:eq, :component_type, Ec2PropertiesInternalType]}

        def dtk_component_ec2_properties(dtk_node)
          ret = 
            if dtk_component = dtk_node.get_components(ComponentTypeFilter).first 
              Service::Component.new(dtk_component).add_link_to_component!
            end
          ret || fail(Error, "Unexpected that no ec2 properties component on node")
        end
        
        def vpc_component
          connected_component(:vpc_subnet).connected_component(:vpc)
        end

        def get_vpc_component
          ret_singleton_or_raise_error('vpc', @reified_target.vpc_components)
        end

        def get_credentials_with_region
          vpc_component.credentials_with_region
        end

      end
    end
  end
end



