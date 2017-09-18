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
     COMPONENT_NAME = 'container'

      module Mixin
        def docker_file?
          unless @docker_file_is_set
            if dockerfile_template = self.dockerfile_template?
              attribute_values = self.provider_attributes.inject({}) { |h, attr| h.merge(attr.display_name => attr[:attribute_value]) }
              @docker_file = MustacheTemplate.render(dockerfile_template, attribute_values)
            end
            @docker_file_is_set = true
          end
          @docker_file
        end
        
        protected
        
        def dockerfile_template?
          self.provider_container? && self.provider_container?.dockerfile_template?
        end
        
        def provider_container?
          unless @provider_container_is_set
            @provider_container = ret_provider_container?
            @provider_container_is_set = true
          end
          @provider_container
        end
        
        private  
        
        def ret_provider_container?
          if container_component_template = self.provider_component_module.get_matching_component_template?(Container::COMPONENT_NAME) 
            Component::Domain::Provider::Container.new(container_component_template)
          end
        end
      end

    end
  end
end


