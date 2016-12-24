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
module DTK; class ConfigAgent
  module Adapter
    class Dynamic < ConfigAgent
      def ret_msg_content(config_node, opts = {})
        component_action   = config_node[:component_actions].first
        method_name        = component_action.method_name? || 'create'
        component          = component_action[:component]
        component_template = component_template(component)
        
        unless dynamic_provider = ActionDef::DynamicProvider.matching_dynamic_provider?(component_template, method_name)
          fail ErrorUsage, "Method '#{method_name}' not defined on component '#{component.display_name_print_form}'"
        end
        pp [:dynamic_provider, dynamic_provider]

        fail 'reached here'
        component_module   = component_action.component_module_name

      end
      
      private
      
      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end

    end
  end
end; end

