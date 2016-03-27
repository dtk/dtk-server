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
          @dtk_node       = dtk_node
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
          # These elemnts of this hash get set on demand
          @cached_attributes = {}
        end

        def credentials_with_region
          @cached_attributes[:credentials_with_region] ||= get_credentials_with_region
        end
        
        def region
          (credentials_with_region || {})[:region]
        end

        def security_group_names
          @cached_attributes[:security_group_names] ||= get_security_group_names
        end

        private

        def get_credentials_with_region
          vpc_reified_component = raise_error_if_not_singleton('vpc', @reified_target.vpcs)
          vpc_reified_component.credentials_with_region
        end

        def get_security_group_names
          # TODO: ifmultiple security grop find ones associated with node
          sg_reified_component = raise_error_if_not_singleton('security group', @reified_target.security_groups)
          sg_reified_component.group_name
        end

        def raise_error_if_empty(type, reified_components)
          if reified_components.empty?
            fail ErrorUsage, "No '#{type}' components in the target service"
          end
        end

        # Returns the reified_component if singleton, otehrwise raises error
        def raise_error_if_not_singleton(type, reified_components)
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


