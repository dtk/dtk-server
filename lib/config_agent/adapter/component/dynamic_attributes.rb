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
  class ConfigAgent::Adapter::Component
    class DynamicAttributes
      # require_relative('dynamic_attributes/transform')
      
      def self.transform(delegated_dynamic_attributes, delegated_task_action_info, base_attributes)
        require 'byebug'; byebug
        output_spec = delegated_task_action_info.output_spec
        ndx_base_attributes = base_attributes.inject({}) { |h, attribute| h.merge(attribute.display_name => attribute) }
        delegated_dynamic_attributes.map do |delegated_attribute_info|
          # Transform.transform(delegated_attribute_info, output_spec, ndx_base_attributes)
        end
        # TODO: stub

        delegated_dynamic_attributes
      end

    end
  end
end
