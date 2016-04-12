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
    class Violation < Assembly::Instance::Violation
      module CommonMixin
        def get_sorted_dtk_aug_attributes(reified_component, *attribute_names)
          attribute_names = attribute_names.map(&:to_s)
          unordered_ret = reified_component.service_component.get_dtk_aug_attributes(*attribute_names)
          # Want to order in same order as names
          ndx_unordered_ret = unordered_ret.inject({}) { |h, a| h.merge(a[:display_name] => a) }
          attribute_names.map { |n| ndx_unordered_ret[n] }
        end
      end
      class ReqUnsetAttr < Assembly::Instance::Violation::ReqUnsetAttr
        include CommonMixin
        def initialize(reified_component, attribute_name)
          aug_attr = get_sorted_dtk_aug_attributes(reified_component, attribute_name).first      
          super(aug_attr, :component)
        end
      end      
      
      class ReqUnsetAttrs < Assembly::Instance::Violation::ReqUnsetAttrs
        include CommonMixin
        def initialize(reified_component, *attribute_names)
          aug_attrs = get_sorted_dtk_aug_attributes(reified_component, *attribute_names)
          super(aug_attrs, :component)
        end
      end

      class IllegalAttrValue < Assembly::Instance::Violation::IllegalAttrValue
        include CommonMixin
        def initialize(reified_component, attribute_name, value, opts = {})
          aug_attr = get_sorted_dtk_aug_attributes(reified_component, attribute_name).first      
          super(aug_attr, value, opts)
        end
      end      

    end
  end
end

