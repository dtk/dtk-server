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
  module CommonDSL
    module ObjectLogic
      class Dependency < ContentInputHash
        def self.generate_content_input(assembly_instance)
          new.generate_content_input!(assembly_instance)
        end
        
        def self.generate_content_input_from_module_refs(module_refs)
          new.generate_content_input_from_module_refs!(module_refs)
        end
        
        def generate_content_input!(assembly_instance)
          # dependent_modules is an array of DTK::ModuleRef objects
          dependent_modules     = assembly_instance.get_dependent_modules
          dependency_info_array = dependent_modules.map { |dep| DependencyInfo.new(dep[:namespace_info], dep[:module_name], dep[:version_info]) }
          
          set_id_handle(assembly_instance)
          generate_content_input_aux!(dependency_info_array)
        end
        
        def generate_content_input_from_module_refs!(module_refs)
          dependency_info_array = module_refs.component_modules.values.map do |module_ref|
            DependencyInfo.new(module_ref.namespace, module_ref.module_name, module_ref.version_string)
          end
          generate_content_input_aux!(dependency_info_array)
        end
        
        private
        
        DependencyInfo = Struct.new(:namespace, :module_name, :version)
        VERSION_WHEN_NIL = 'master'
        def generate_content_input_aux!(dependency_info_array)
          dependency_info_array.inject(ContentInputHash.new)  do |h, dep| 
            h.merge("#{dep.namespace}/#{dep.module_name}" => (dep.version || VERSION_WHEN_NIL)) 
          end
        end

      end
    end
  end
end
