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
    class LinkParams
      class Common < self
        # params can have keys:
        #   :component_name (required)
        #   :node_name
        def initialize(assembly_instance, params = {})
          @assembly_instance = assembly_instance
          @component_name    = params[:component_name] || fail(Error, "Unexpected that params[:component_name] is nil") 
          @node_name         = params[:node_name]
        end

        attr_reader :component_name

        private
        
        attr_reader :assembly_instance, :node_name

        def component_object_common?(ref_assembly_instance)
          begin 
            Component.name_to_object(assembly_instance.model_handle(:component), user_friendly_component_name, assembly_id: ref_assembly_instance.id)
          rescue ErrorNameDoesNotExist
            nil
          end
        end

        def user_friendly_component_name
          node_name ? "#{node_name}/#{component_name}" : component_name
        end

      end

      class Base < Common
        def component_object?
          component_object_common?(assembly_instance)
        end
      end
      
      class Dependency < Common
        # params can have keys:
        #   :component_name (required)
        #   :node_name
        #   :external_assembly_instance
        def initialize(assembly_instance, params = {})
          super
          @external_assembly_instance = params[:external_assembly_instance]
        end

        def component_object?
          component_object_common?(external_assembly_instance || assembly_instance)
        end

        def component_name_with_external_service
          external_assembly_instance ? "#{user_friendly_component_name}(#{external_assembly_instance.display_name})" :
            user_friendly_component_name
        end

        private

        attr_reader :external_assembly_instance

      end

    end
  end
end
