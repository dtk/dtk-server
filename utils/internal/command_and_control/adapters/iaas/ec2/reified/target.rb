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
  module CommandAndControlAdapter::Ec2::Reified
    class Target < DTK::Service::Reified::Components
      r8_nested_require('target', 'component')

      def initialize(target_service)
        @target_service = target_service
        # The elements in this hash get set on demand
        # They correspond to all the component types in a target service
        @cache_components = {}
      end
      
      def vpcs
        @cache_components[:vpcs] ||= get_vpcs
      end

      def security_groups
        @cache_components[:security_groups] ||= get_security_groups
      end

      def get_vpcs
        vpc_service_components = @target_service.matching_components?(Component::Type.vpc) || []
        vpc_service_components.map { |vpc_service_component| Component::Vpc.new(vpc_service_component) }
      end

      def get_security_groups
        sg_service_components = @target_service.matching_components?(Component::Type.security_group) || []
        sg_service_components.map { |sg_service_component| Component::SecurityGroup.new(sg_service_component) }
      end
    end
  end
end

