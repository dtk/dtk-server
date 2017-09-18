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
      module Mixin

        def docker_file?
          if @docker_file_is_set
            @docker_file
          else
            @docker_file_is_set = true
            if dockerfile_template = self.dockerfile_template?
              # TODO: This should be moved to provider itself, but if temporarly stay in here shuld be in attribute mixin
              # TODO: should this case on whether there is byebug enabled for this step
              ActionDef::DynamicProvider.update_gem_attribute_for_byebug!(provider_attributes)
              attribute_values = provider_attributes.inject({}) { |h, attr| h.merge(attr.display_name => attr[:attribute_value]) }
              @docker_file = MustacheTemplate.render(dockerfile_template, attribute_values)
            end
          end
        end
        
        protected
        
        def dockerfile_template?
          self.provider_container? && self.provider_container?.dockerfile_template?
        end
        
        def provider_container?
          if @provider_container_is_set
            @provider_container
          else
            @provider_container_is_set = true
            @provider_container = ret_provider_container?
          end
        end
        
        private  
        
        CONTAINER_COMPONENT_NAME = 'container'
        
        def ret_provider_container?
          if container_component_template = self.provider_component_module.get_matching_component_template?(CONTAINER_COMPONENT_NAME) 
            Component::Domain::Provider::Container.new(container_component_template)
          end
        end
      end

    end
  end
end


