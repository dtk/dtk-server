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
  class Assembly::Instance
    module ComponentTemplateMixin
      def find_matching_aug_component_template?(component_type, component_module_refs)
        Component::Template::Augmented.find_matching_component_template(self, component_type, component_module_refs, donot_raise_error: true)
      end


      # opts can have keys:
      #   :donot_raise_error
      def simple_find_matching_aug_component_template(component_type, opts = {})
        find_matching_aug_component_template(component_type, self.component_module_refs, donot_raise_error: opts[:donot_raise_error], dependent_modules: dependent_modules)
      end

      # opts can have keys:
      #   :donot_raise_error
      #   :dependent_modules
      def find_matching_aug_component_template(component_type, component_module_refs, opts = {})
        Component::Template::Augmented.find_matching_component_template(self, component_type, component_module_refs, opts)
      end

      private
      
      def dependent_modules
        # put in info for base module
        base_module = base_module_info
        dependent_modules = { "#{base_module.namespace}/#{base_module.module_name}" => base_module.version }
        
        # put in info for nested module
        self.component_module_refs.module_refs_array.each { |dep| dependent_modules.merge!("#{dep[:namespace_info]}/#{dep[:display_name]}" => extract_version(dep[:version_info])) }
        
        dependent_modules
      end
      

      BaseModuleInfo = Struct.new(:namespace, :module_name, :version)
      def base_module_info
        augmented_module_branch = get_service_module.get_augmented_module_branch
        BaseModuleInfo.new(augmented_module_branch[:namespace], augmented_module_branch[:module_name], augmented_module_branch[:version])
      end
      
      def extract_version(version_obj)
        version_obj.is_a?(String) ? version_obj : version_obj.version_string
      end

    end
  end
end
