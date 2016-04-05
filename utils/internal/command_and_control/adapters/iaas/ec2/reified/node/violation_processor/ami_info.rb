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
    module Node::ViolationProcessor
      class AmiInfo
        attr_reader :ami, :os_type

        def initialize(hash)
          @ami     = hash['ami']
          @os_type = hash['os_type']
          @sizes  = hash['sizes']
        end
        private: initialize

        # returns [ami_info, violations]; ami_info could be nil and violations can be []
        def self.compute?(reified_node) 
          violations = []
          ami_info   = nil
          
          image_label = reified_node.image_label
          vpc_images  = reified_node.vpc_images
          unless image_label and vpc_images
            return [ami_info, violations] 
          end

          if ami_info_hash = vpc_images[image_label]
            ami_info = new(ami_info_hash)
          else
            legal_labels = vpc_images.keys
            violations << Violation::IllegalAttrValue.new(reified_node, :image_label, image_label, legal_values: legal_labels) 
          end
          [ami_info, violations]
        end
      end
    end
  end
end

