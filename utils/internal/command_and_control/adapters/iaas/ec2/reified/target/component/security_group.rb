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
      class SecurityGroup < self
        attr_reader :group_name, :group_id
      
        def initialize(reified_target, sg_service_component)
          super(reified_target, sg_service_component)
          @group_name, @group_id, @vpc_id = get_attribute_values(:group_name, :id, :vpc_id)
        end 
        
        def validate_and_converge!
          ret = []
          # check that either group_name or group_id is set
          if @group_name.nil? and @group_id.nil?
            aug_attrs = get_dtk_aug_attributes(:group_name, :id)
            return [Violation::ReqUnsetAttrs.new(aug_attrs)]
          end
          ret
        end
        
        private
        
        # connected vpc
        def vpc
          @vpc ||= get_vpc
        end
        
        def get_vpc
          vpcs = @reified_target.get_all(:vpc).select{ |vpc| vpc.id == @vpc_id }
          unless vpcs.size == 1
            fail Error, "Unexpected that the matching vpc is not found" 
          end
        end
      end
    end
  end
end


