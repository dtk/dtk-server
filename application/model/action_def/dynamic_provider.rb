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
  class ActionDef
    class DynamicProvider
      def initialize(action_def_params, assembly_instance)
        @action_def_params      = action_def_params
        @provider_module_name   = 'ruby-provider' # TODO: stub 
        @container_component       = ret_container_component?(@provider_module_name, assembly_instance) 
      end
      private :initialize
      
      def self.matching_dynamic_provider?(component_template, method_name, assembly_instance)
        if action_def_params = ActionDef.get_matching_action_def_params?(component_template, method_name)
          new(action_def_params, assembly_instance)
        end
      end
      
      private
      

      def ret_container_component?(provider_module_name, assembly_instance)
        component_module_refs  = assembly_instance.component_module_refs
        container_component_type  = container_component_type(provider_module_name)

        # container_dtk_component is acomponent template with default attribute values
        if container_dtk_component = assembly_instance.find_matching_aug_component_template?(container_component_type, component_module_refs) 
          Component::Domain::Provider::Container.new(container_dtk_component)
        end
      end

      CONTAINER_COMPONENT_NAME = 'container'
      def container_component_type(provider_module_name)
        Component.component_type_from_module_and_component(provider_module_name, CONTAINER_COMPONENT_NAME)
      end

    end
  end
end
