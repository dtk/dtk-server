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
    class Import::Assemblies
      module Assembly
        require_relative('assembly/top')
        require_relative('assembly/attributes')

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
            # Aldin: 06/27/2016: remove need for version_proc_class
            integer_version = 4 # stubbed this until we remove version_proc_class
            version_proc_class = load_and_return_version_adapter_class(integer_version)
            
            db_update_hash = Assembly::Top.db_update_hash(parsed_assembly, @module_branch, @module_name)
            @db_updates_assemblies['component'].merge!(assembly_ref => db_update_hash)          
            assembly_ref_pointer = @db_updates_assemblies['component'][assembly_ref] 
            
            # Aldin: 06/27/2016: There is alot of code in parsing workflow; I will handle conversion to
            # split between dtk-dsl and code I will put in assembly/workflows
            # add in workflows (task_templates)
            workflows_db_update_hash  = version_proc_class.import_task_templates(parsed_assembly)
            assembly_ref_pointer.merge!('task_template' => workflows_db_update_hash.mark_as_complete)
            
            assembly_attrs_db_update_hash = Assembly::Attributes.db_update_hash(parsed_assembly.val(:Attributes) || [])
            # Aldin: 06/27/2016: Moving mark as complete to this level
            assembly_ref_pointer.merge!('attribute' => assembly_attrs_db_update_hash.mark_as_complete)

            # add to @db_updates_assemblies['node'] the db update hash that captures the nodes section
            # Aldin: 06/27/2016: create new file assembly/nodes and put in replacement for @version_proc_class.import_nodes
            # have this only return db hash updates and not error by raising ruby on first error
            # this wil allow you to remove raise db_updates if ServiceModule::ParsingError.is_error?(db_updates)
            # TODO: next line needed until convert from version_proc_class.import_nodes
            if parsed_nodes = parsed_assembly.delete(:nodes)
              parsed_assembly['nodes'] = parsed_nodes.inject({}) { |h, parsed_node| h.merge(parsed_node.req(:Name) => parsed_node) }
              node_bindings_hash = {}
              db_updates = version_proc_class.import_nodes(@container_idh, @module_branch, assembly_ref, parsed_assembly, node_bindings_hash, @component_module_refs, default_assembly_name: assembly_name)
              raise db_updates if ServiceModule::ParsingError.is_error?(db_updates)
              @db_updates_assemblies['node'].merge!(db_updates)
            end

            
            @ndx_assembly_hashes[assembly_ref] ||= parsed_assembly
            
            # Aldin: 06/27/2016: See how to remove this
            @ndx_version_proc_classes[assembly_ref] ||= version_proc_class
          end
        end
      end
    end
  end
end
