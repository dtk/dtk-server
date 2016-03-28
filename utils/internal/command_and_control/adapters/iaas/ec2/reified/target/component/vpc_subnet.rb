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
        def initialize(reified_target, vpc_subnet_service_component)
          super(reified_target, vpc_subnet_service_component)
          @id, @vpc_id = get_attribute_values(:id, :vpc_id)
          @cached_connected_components = {} #cache connected objects
        end

        # Returns an array of violations; if no violations [] is returned
        def validate_and_converge!
          if @id.nil?
            aug_attr = get_dtk_aug_attributes(:id).first
            [Violation::ReqUnsetAttr.new(aug_attr)]
          elsif @vpc_id
            # TODO: could validate @id and @vpc_id
            []
          else
            validate_id_and_get_and_propagate_vpc_id!
            []
          end
        end

        private

        def vpc_component
          @cached_connected_components[:vpc] ||= get_connected_component(:vpc)
        end

        def validate_id_and_get_and_propagate_vpc_id!
          # TODO: stub
          vpc_component
        end

      end
    end
  end
end


