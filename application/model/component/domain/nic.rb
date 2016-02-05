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
module DTK; class Component
  class Domain
    class NIC < self
      attr_reader :security_groups
      def initialize(component)
        super
        @security_groups = match_attribute_value?(:security_groups)
      end

      def self.get_primary_nic?(node)
        ret = on_node?(node).select { |nic| nic.is_primary? }
        case ret.size
          when 0 then nil
          when 1 then ret.first
          else fail ErrorUsage, "Multiple primary nic components configured on node '#{node.get_field?(:display_name)}'"
        end
      end

      def subnet_id?
        nil
      end
      def is_primary?
        true
      end

      def self.create(component)
        if VPC.is_a?(component)
          VPC.new(component)
        else
          new(component)
        end
      end
      
      def self.component_types
        VPC.component_types
      end
      
      class VPC < self
        attr_reader :subnet_id
        def initialize(component)
          super
          @subnet_id = match_attribute_value?(:subnet_id)
        end

        def subnet_id?
          @subnet_id
        end

        def is_primary?
          ComponentTypes::Primary.include?(@component_type)
        end

        def self.component_types
          ComponentTypes::All
        end

        module ComponentTypes
          Primary   = %w{nic__primary_ec2_vpc}
          Secondary = %w{nic__secondary_ec2_vpc}
          All       = Primary + Secondary
        end
      end

    end
  end
end; end