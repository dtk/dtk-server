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
    class Node
      module ViolationProcessor
        r8_nested_require('violation_processor', 'ami_info')

        def self.validate_and_fill_in_values(service, opts = {})
          Node.create_nodes_from_service(service, opts).inject([]) do |a, reified_node|
            a += reified_node.validate_and_fill_in_values!
          end
        end

        module Mixin
          def validate_and_fill_in_values!
            ami_info, violations = AmiInfo.compute?(self)
            return violations unless violations.empty?

            violations = validate_and_fill_in_values__ami!(ami_info)
            return violations unless violations.empty?
            
            violations += validate_and_fill_in_values__os_type(ami_info)

            violations += validate_and_fill_in_values__instance_type(ami_info)

            violations
          end

          private

          # ami_info can be nil
          def validate_and_fill_in_values__ami!(ami_info)
            violations = []
            if ami 
              # ami value will be validated during create node
              update_image_id!(ami)
            else
              unless ami_info
                violations << Violation::ReqUnsetAttrs.new(self, :ami, :image)
              else
                update_image_id!(ami_info.ami)
                update_and_propagate_dtk_attributes(ami: ami_info.ami) 
              end
            end
            violations
          end

          # ami_info will not be nil
          def validate_and_fill_in_values__os_type(ami_info)
            violations = []
            if os_type
              # TODO: may validate os_type
              update_os_type!(os_type)
            elsif ami_info
              update_os_type!(ami_info.os_type)
              update_and_propagate_dtk_attributes(os_type: ami_info.os_type) 
            end
            violations
          end

          # ami_info will not be nil
          def validate_and_fill_in_values__instance_type(ami_info)
            violations = []
            if instance_type
              # instance_type value will be validated when create node
              update_instance_type!(instance_type)
            else
              unless size
                violations << Violation::ReqUnsetAttrs.new(self, :size, :instance_type)
              else
                calculated_instance_type, more_violations = ami_info.instance_type?(size)
                violations += more_violations
                if calculated_instance_type  
                  update_instance_type!(calculated_instance_type)
                  update_and_propagate_dtk_attributes(instance_type: calculated_instance_type)
                end
              end
            end
            violations
          end

        end
      end
    end
  end
end

