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
    class Import::ServiceModule
      module Assembly
        require_relative('assembly/top')
        require_relative('assembly/attributes')
        require_relative('assembly/nodes')
        require_relative('assembly/components')

        module Mixin
          # opts can have keys:
          #   :module_version
          def process_assembly!(parsed_assembly, opts = {})
            # DTK-2554: when we treat service instance modules along with base service ones dont want to call below
            if parsed_nodes = parsed_assembly.val(:Nodes)
              BaseService::NodePropertyComponent.create_node_property_components?(parsed_nodes)
            end

            # Aldin: 06/27/2016: move this logic to the parser
            # @service_module.parse_assembly_wide_components!(hash_content)

            assembly_name = parsed_assembly.req(:Name)
            assembly_ref = @service_module.assembly_ref(assembly_name, opts[:module_version])
            
            db_update_hash = Assembly::Top.db_update_hash(parsed_assembly, @module_branch, @module_name)
            @db_updates_assemblies['component'].merge!(assembly_ref => db_update_hash)          
            assembly_ref_pointer = @db_updates_assemblies['component'][assembly_ref] 
            
            # Aldin: 06/27/2016: There is alot of code in parsing workflow; I will handle conversion to
            # split between dtk-dsl and code I will put in assembly/workflows
            # add in workflows (task_templates)
            #
            # workflows_db_update_hash  = version_proc_class.import_task_templates(parsed_assembly)
            # assembly_ref_pointer.merge!('task_template' => workflows_db_update_hash.mark_as_complete)

            assembly_attrs_db_update_hash = Assembly::Attributes.db_update_hash(parsed_assembly.val(:Attributes) || [])
            assembly_ref_pointer.merge!('attribute' => assembly_attrs_db_update_hash.mark_as_complete)

            # if parsed_nodes = parsed_assembly.delete(:nodes)
            if parsed_nodes = parsed_assembly.val(:Nodes)
              nodes_db_update_hash = Assembly::Nodes.db_update_hash(@container_idh, assembly_ref, parsed_nodes, @component_module_refs, default_assembly_name: assembly_name)
              @db_updates_assemblies['node'].merge!(nodes_db_update_hash)
            end

            @ndx_assembly_hashes[assembly_ref] ||= parsed_assembly
          end
        end
      end
    end
  end
end
