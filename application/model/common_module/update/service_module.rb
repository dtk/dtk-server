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
    class Update
      class ServiceModule < self
        # This method creates af necssary a service module and branch from the common module module_branch 
        # with matching namespace, module name, and version
        # It then updates the service module branch object model from parse_hash 
        def self.create_or_update_from_common_module(common_module__module_branch, parse_hash)
          module_branch = create_or_ret_module_branch(:service_module, common_module__module_branch)
          update_service_module_from_dsl(module_branch, parse_hash)
        end
        
        private
        
        # TODO: Aldin 6/22/2016
        # Write this method to update or create the data model objects that make up teh service model.
        # Mimic the existing call that updates the service model from clone
        # https://github.com/dtk/dtk-server/blob/DTK-2554/application/model/module/service_module/dsl.rb#L204
        # start by implementing update to the component module refs and the assembly
        # Right now we will just update the object model, but not create or update a service moduel git repo
        # 
        def self.update_service_module_from_dsl(module_branch, parse_hash)
          update_component_module_refs(module_branch, parse_hash)
          update_assemblies(module_branch, parse_hash)
        end
        
        def self.update_component_module_refs(module_branch, parse_hash)
          if dependent_modules = parse_hash[:dependent_modules]
            # use dependent_modules to pupulate the component module refs on
            # service module module_branch
          end
        end
        
        def self.update_assemblies(module_branch, parse_hash)
          # in base module there wil be the canoical key that assemblies are assigned to;
          # if it ios assemblies; they we want to 
          # use assemblies = parse_hash[:assemblies]
          # to poplate the assemblies on the service module module_branch
          # Try to reuse as much as possible teh existing code that is used in teh assebly processing part of
          # https://github.com/dtk/dtk-server/blob/DTK-2554/application/model/module/service_module/dsl.rb#L204
          # The way that parse has well be formed is different but population from the parse has should be very simple 
          # and in fleshing out the parse hash keys in dtk-=dsl templates; we could choose keys to make this as aligned as possible
          # One thing to first look at is trapping the function taht parses assemblies and look at the parse hash key structure to
          # use in building up dtk-dsl parse templates
        end
      end
    end
  end
end
