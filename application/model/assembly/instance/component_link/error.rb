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
  class Assembly::Instance::ComponentLink
    module Error
      # in methods below opts can have keys:
      #   :link_name

      def self.raise_bad_base_component(base_component_name, dep_component_name, opts = {})
        fail ErrorUsage, "Bad base component in #{component_link_ref(base_component_name, dep_component_name, opts)}"
      end

      def self.raise_bad_dep_component(base_component_name, dep_component_name, opts = {})
        fail ErrorUsage, "Bad dependent component in #{component_link_ref(base_component_name, dep_component_name, opts)}"
      end

      def self.raise_link_name_error(matching_link_types, base_component, dep_component, opts = {})
        base_component_name = base_component.component_type_print_form
        dep_component_name = dep_component.component_type_print_form
        error_msg = 
          if link_name =  opts[:link_name]
            "Specified link name '#{link_name}' does not match any of the dependencies defined between component type '#{base_component_name}' and component type '#{dep_component_name}': #{matching_link_types.join(',')}"
          elsif matching_link_types.empty?
            "There are no links defined between component type '#{base_component_name}' and component type '#{dep_component_name}'"
          elsif matching_link_types.size > 1
            "Ambiguous which link between component type '#{base_component_name}' and component type '#{dep_component_name}' selected; select one of #{matching_link_types.join(',')})"
          end
        fail ErrorUsage, error_msg if error_msg
      end

      private

      def self.component_link_ref(base_component_name, dep_component_name, opts = {})
        "link " + (opts[:link_name] ? "'#{opts[:link_name]}' " : " ") + "on base component '#{base_component_name}' to dependent component '#{dep_component_name}'"
      end

    end
  end
end
