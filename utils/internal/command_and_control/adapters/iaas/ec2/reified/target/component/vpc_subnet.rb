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
  class CommandAndControlAdapter::Ec2::Reified::Target
    class Component
      class VpcSubnet < self
        class Attr < Component::Attribute
          Names = [:id, :vpc_id]
        end

        def initialize(reified_target, vpc_subnet_service_component)
          super(reified_target, vpc_subnet_service_component)
        end

        # Returns an array of violations; if no violations [] is returned
        def validate_and_converge!
          id, vpc_id = get_attribute_values(Attr.id, Attr.vpc_id)

          unless id
            aug_attr = get_dtk_aug_attributes(Attr.id).first
            return [Violation::ReqUnsetAttr.new(aug_attr)]
          end

          unless aws_vpc_subnet = aws_vpc_subnet?(id)
            return [Violation::InvalidVpcSubnetId.new(id)]
          end

          get_and_propagate_vpc_id(aws_vpc_subnet)
          []
        end

        private

        def vpc_component
          # TODO: might use same for as attribute for component and use Component.vpc
          use_and_set_connected_component_cache(:vpc) { get_connected_component(:vpc) }
        end

        def aws_vpc_subnet?(vpc_subnet_id)
          vpc_component.aws_conn.subnet?(vpc_subnet_id)
        end

        def get_and_propagate_vpc_id(aws_vpc_subnet)
          vpc_component.id = aws_vpc_subnet[:vpc_id]
        end

      end
    end
  end
end


