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
# TODO: rewrite to use style of vpc_subnet for validate and converge
module DTK
  class CommandAndControlAdapter::Ec2::Reified::Target
    class Component
      class SecurityGroup < self
        attr_reader :group_name, :group_id
      
        def initialize(reified_target, sg_service_component)
          super(reified_target, sg_service_component)
          # TODO: might not have vpc_id since can get this from component link
          @group_name, @group_id, @vpc_id = get_attribute_values(:group_name, :id, :vpc_id)
        end 

        # Returns an array of violations; if no violations [] is returned
        def validate_and_converge!
          if @group_id
            ret = violation_group_id?
            if ret.empty?
              set_group_name! unless @group_name
              # TODO: if @group_name is set could also if it is a valid security_group name
            end
            ret
          elsif @group_name
            # TODO: rewrite to use style of vpc_subnet for validate and converge
            validate_group_name_and_set_group_id!
          else
            # Violation since one of group_name or group_id must be set
            aug_attrs = get_dtk_aug_attributes(:group_name, :id)
            [Violation::ReqUnsetAttrs.new(aug_attrs)]
          end
        end
        
        private

        def vpc_component
          use_and_set_connected_component_cache(:vpc) { get_connected_component(:vpc) }
        end

        def validate_group_name_and_set_group_id!
          # TODO: stub
          # use vpc_component.aws_conn
          []
        end
      end
    end
  end
end


