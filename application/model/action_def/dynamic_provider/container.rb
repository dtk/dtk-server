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
  class ActionDef::DynamicProvider
    module Container
      DOMAIN_COMPONENT_NAME = 'container'

      module Mixin
        def docker_file?
          if @docker_file_set
            @docker_file
          else
            @docker_file_set = true
            if dockerfile_template = (@container_component && @container_component.dockerfile_template?) 
              attribute_values = provider_attributes.inject({}) { |h, attr| h.merge(attr.display_name => attr[:attribute_value]) } 
              @docker_file = MustacheTemplate.render(dockerfile_template, attribute_values)
            end
          end
        end
      
        private

        def set_container_component!(provider_module_name, assembly_instance)
          @container_component = Container.ret_container_domain_component?(provider_module_name, assembly_instance)
        end
      end
      
      def self.ret_container_domain_component?(provider_module_name, assembly_instance)
        component_module_refs    = assembly_instance.component_module_refs
        container_component_type = container_component_type(provider_module_name)
        
        if container_dtk_component = assembly_instance.find_matching_aug_component_template?(container_component_type, component_module_refs) 
          Component::Domain::Provider::Container.new(container_dtk_component)
        end
      end

      private      
  
      def self.container_component_type(provider_module_name)
        Component.component_type_from_module_and_component(provider_module_name, DOMAIN_COMPONENT_NAME)
      end
      
    end
  end
end


