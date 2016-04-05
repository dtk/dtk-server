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

            # TODO: temp
            # ami = ami() || (@external_ref || {})[:image_id]

            violations = validate_and_fill_in_values__ami!(ami_info)
            return violations unless violations.empty?
            
            violations += validate_and_fill_in_values__os_type(ami_info)

            violations += validate_and_fill_in_values__instance_type(ami_info)

            violations
          end

          private

          def validate_and_fill_in_values__ami!(ami_info)
            violations = []
            unless ami # ami value wil be validated during create node
              unless ami_info
                violations << Violation::ReqUnsetAttrs.new(self, :ami, :image_label)
              else
                update_and_propagate_dtk_attributes(ami: ami_info.ami) 
              end
            end
            violations
          end
          
          def validate_and_fill_in_values__os_type(ami_info)
            violations = []
            if os_type
              # TODO: may validate os_type
            else
              update_and_propagate_dtk_attributes(os_type: ami_info.os_type) if ami_info
            end
            violations
          end

          def validate_and_fill_in_values__instance_type(ami_info)
            violations = []
            unless instance_type # instance_type value wil be validated when create node
              unless ami_info
                violations << Violation::ReqUnsetAttrs.new(self, :size, :instance_type)
              else
                calculated_instance_type, more_violations = ami_info.instance_type?
                violations += more_violations
                if calculated_instance_type  
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

