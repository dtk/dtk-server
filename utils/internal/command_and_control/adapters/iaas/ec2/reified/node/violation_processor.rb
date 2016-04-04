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
        def self.validate_and_fill_in_values(service, opts = {})
          if reified_node = Node.create_from_service?(service, opts)
            reified_node.validate_and_fill_in_values!
          end
        end

        module Mixin
          def validate_and_fill_in_values!
            ret = []
            return ret unless ami # validating ami when doing create node
            
            if image_label
              computed_ami, violations = validate_image_label_and_compute_ami 
              if violations
                ret += violations
              else
                #computed_ ami wil be non null
                update_and_propagate_dtk_attributes(ami: computed_ami)
              end
            else
              # TODO: temp (use of external_ref[:image_id]
              unless computed_ami = @external_ref[:image_id]
                ret << Violation::ReqUnsetAttrs.new(self, :ami, :image_label)
              else
                update_and_propagate_dtk_attributes(ami: computed_ami)
              end
            end
            ret
          end

          private

        # returns [computed_ami, violations]
          def validate_image_label_and_compute_ami 
            violations = []
            computed_ami = nil
            if vpc_images
              unless computed_ami = vpc_images[image_label]
                legal_labels = vpc_images.keys
                violations << Violation::InvalidImageLabel.new(image_label, legal_labels) 
              end
            else
              violations << Violation::ReqUnsetAttr.new(self, :vpc_images)
            end
            [computed_ami, violations]
          end
        end
      end
    end
  end
end

