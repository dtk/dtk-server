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

module DTK module CommandAndControlAdapter::Ec2::Reified
  class Target
    class Component < DTK::Service::Reified::Component
      require_relative('component/role')
      require_relative('component/iam_user')
      require_relative('component/vpc')
      require_relative('component/vpc_subnet')
      require_relative('component/security_group')

      include ConnectedComponentMixin

      def initialize(reified_target, service_component)
        super(service_component)
        @reified_target = reified_target
      end

      # Returns an array of Violation objects
      def validate_and_fill_in_values!
        Log.error("Abstract method that should be overwritten for class '#{self.class}'")
        []
      end

      def clear_all_attribute_caches!
        @reified_target.clear_all_attribute_caches!
      end

      def connected_component(conn_cmp_type)
        connected_component_aux(conn_cmp_type, @reified_target)
      end

      def connected_component?(conn_cmp_type)
        get_connected_component?(conn_cmp_type, @reified_target)
      end

      private

      def self.legal_attributes
        self::Attributes
      end
    end
  end
end; end

