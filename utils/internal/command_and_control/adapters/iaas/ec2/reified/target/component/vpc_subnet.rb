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
        Attributes = [:subnet_id, :vpc_id, :cidr_block, :availability_zone]

        def initialize(reified_target, vpc_subnet_service_component)
          super(reified_target, vpc_subnet_service_component)
        end

        # Returns an array of violations; if no violations [] is returned
        def validate_and_fill_in_values!
          return([Violation::ReqUnsetAttr.new(self, :subnet_id)]) unless subnet_id

          unless aws_vpc_subnet = aws_vpc_subnet?(subnet_id)
            legal_subnet_ids = vpc_component.aws_conn.subnets.map { |vpc_subnet| vpc_subnet[:subnet_id] }
            unset_attribute_when_invalid(:subnet_id)
            return [Violation::InvalidVpcSubnetId.new(subnet_id, legal_subnet_ids: legal_subnet_ids)]
          end

          get_and_propagate_vpc_id(aws_vpc_subnet)
          set_attributes_from_aws!(aws_vpc_subnet)
          []
        end

        private

        def set_attributes_from_aws!(aws_vpc_subnet)
          name_value_pairs = Aux.hash_subset(aws_vpc_subnet, [:cidr_block, :availability_zone])
          update_and_propagate_dtk_attributes(name_value_pairs, prune_nil_values: true)
        end

        def vpc_component
          connected_component(:vpc)
        end

        def aws_vpc_subnet?(vpc_subnet_id)
          vpc_component.aws_conn.subnet?(vpc_subnet_id)
        end

        def get_and_propagate_vpc_id(aws_vpc_subnet)
          vpc_component.vpc_id = aws_vpc_subnet[:vpc_id]
        end
      end
    end
  end
end


