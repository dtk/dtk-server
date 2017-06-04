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
        dep_component_name =  dep_component.component_type_print_form
        specified_link_name = (opts[:link_name] == dep_component_name ? nil : opts[:link_name]) # nil if linkanem same as depedency or opts[:link_name] is nil
        common_args = [matching_link_types, base_component_name, dep_component_name]
        error_msg = (specified_link_name ? error_message_when_specified_link_name(specified_link_name, *common_args) : error_message_when_no_specified_link_name(*common_args))
        fail ErrorUsage, error_msg if error_msg
      end
      
      private
      
      def self.error_message_when_specified_link_name(specified_link_name, matching_link_types, base_component_name, dep_component_name)
        if matching_link_types.empty?
          "There are no links defined from component type '#{base_component_name}' to component type '#{dep_component_name}'"
        else
          "Specified link name '#{specified_link_name}' does not match any links defined from component type '#{base_component_name}' to component type '#{dep_component_name}'; legal link names are: #{matching_link_types.join(', ')}"
        end
      end

      def self.error_message_when_no_specified_link_name(matching_link_types, base_component_name, dep_component_name)
        case matching_link_types.size
        when 0
          "There are no links defined from component type '#{base_component_name}' to component type '#{dep_component_name}'"
        when 1        
          "The link from component type '#{base_component_name}' to component type '#{dep_component_name}' must be specified with link name '#{matching_link_types.first}'"
        else
          "The link from component type '#{base_component_name}' to component type '#{dep_component_name}' must be specified with link name from: #{matching_link_types.join(',')}"
        end
      end

      def self.component_link_ref(base_component_name, dep_component_name, opts = {})
        "link " + (opts[:link_name] ? "'#{opts[:link_name]}' " : " ") + "on base component '#{base_component_name}' to dependent component '#{dep_component_name}'"
      end

    end
  end
end
