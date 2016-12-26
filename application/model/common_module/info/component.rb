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
  class CommonModule
    module Info
      class Component < ComponentModule
        require_relative('component/remote')
        extend  CommonModule::ClassMixin
        include CommonModule::Mixin
        
        def self.info_type
          :component_info
        end
        
        def self.get_module_dependencies(project, rsa_pub_key, remote_params)
          missing_modules, required_modules, dependency_warnings = get_required_and_missing_modules(project, remote_params, rsa_pub_key)
          {
            missing_module_components: missing_modules,
            dependency_warnings: dependency_warnings,
            required_modules: required_modules
          }
        end
        
        def self.list_remotes(_model_handle, rsa_pub_key = nil, opts = {})
          Repo::Remote.new.list_module_info(module_type, rsa_pub_key, opts.merge!(ret_versions_array: true))
        end
        
        private
        
        # This causes all get_obj(s) class an instance methods to return Info::Component objects, rather than ComponentModule ones
        def self.get_objs(model_handle, sp_hash, opts = {})
          if model_handle[:model_name] == :component_module
            super.map { |component_module| copy_as(component_module) }
          else
            super
          end
        end

      end
    end
  end
end

