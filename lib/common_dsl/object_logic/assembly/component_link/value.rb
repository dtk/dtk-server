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
module DTK; 
  class CommonDSL::ObjectLogic::Assembly::ComponentLink
    class Value < ::Hash

      def initialize(dependency, external_service_name)
        super()
        replace(dependency: dependency, external_service_name: external_service_name)
      end

      def dependency_link_params(assembly_instance)
        component_name, node_name = component_and_node_names
        link_params_opts = {
          component_name: component_name, 
          node_name: node_name, 
          external_assembly_instance: external_assembly_instance?(assembly_instance)
        }
        link_params_class::Dependency.new(assembly_instance, link_params_opts) 
      end
      
      private
      
      def dependency
        self[:dependency]
      end
      
      def external_service_name
        self[:external_service_name]
      end

      def external_assembly_instance?(assembly_instance)
        Assembly::Instance.name_to_object(assembly_instance.model_handle, external_service_name)  if external_service_name
      end    

      # returns [component_name, node_name] # node_name can be nil
      def component_and_node_names
        component_name = node_name = nil
        error = false
        unless dependency.kind_of?(::String)
          error = true
        else
          split = dependency.split('/')
          case split.size
          when 1
            component_name = split[0]
          when 2
            component_name = split[1]
            error = true unless node_name = NodeComponent.node_name_if_node_component?(split[0])
          else
            error = true
          end
        end
        fail ErrorUsage, "The term '#{dependency.inspect}' does not have valid syntax for a component link dependency" if error        
        [component_name, node_name]
      end

      def link_params_class
        Assembly::Instance::ComponentLink::LinkParams
      end

    end
  end
end

