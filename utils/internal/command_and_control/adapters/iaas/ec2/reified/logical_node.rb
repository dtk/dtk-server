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
      class LogicalNode < DTK::Service::Reified::Component
        # opts can have keys
        # :reified_target
        def initialize(dtk_node, opts = {})
          super()
          @dtk_node       = dtk_node
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
        end

        def credentials_with_region
          use_and_set_attribute_cache(:credentials_with_region) { get_credentials_with_region }
        end
        
        def region
          (credentials_with_region || {})[:region]
        end

        def security_groups
          use_and_set_attribute_cache(:security_groups) { get_security_groups }
        end

        private

        def vpc_component
          use_and_set_connected_component_cache(:vpc) { get_vpc_component }
        end

        def get_vpc_component
          ret_singleton_or_raise_error('vpc', @reified_target.vpc_components)
        end

        def get_credentials_with_region
          vpc_component.credentials_with_region
        end

        def get_security_groups
          # TODO: if multiple security groups find ones associated with node
          # Below finds all associated with the vpc that the security group is connected to
          matching_sg_reified_components = @reified_target.get_matching_security_groups(vpc_component.id)
          raise_error_if_empty('security group',matching_sg_reified_components)
          matching_sg_reified_components.map(&:security_group_struct)
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


