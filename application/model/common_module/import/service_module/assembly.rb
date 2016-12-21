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
        require_relative('assembly/node_property_component')

        module Mixin
          def process_assembly!(parsed_assembly, module_local_params)
            if parsed_nodes = parsed_assembly.val(:Nodes)
              NodePropertyComponent.create_node_property_components?(parsed_nodes)
            end

            if module_version = module_local_params.version
              module_version = nil if module_version.eql?('master')
            end

            assembly_name = parsed_assembly.req(:Name)
            assembly_ref = @service_module.assembly_ref(assembly_name, module_version)
            
            db_update_hash = Assembly::Top.db_update_hash(parsed_assembly, @module_branch, @module_name)
            @db_updates_assemblies['component'].merge!(assembly_ref => db_update_hash)          
            assembly_ref_pointer = @db_updates_assemblies['component'][assembly_ref] 

            if workflows_parse = parsed_assembly.val(:Workflows)
              workflows_db_update_hash = workflows_parse.inject({}) do |h, (workflow_name, workflow_content)| 
                task_action_name = task_action_name(workflow_name)
                h.merge(task_action_name => { 'task_action' => task_action_name, 'content' => workflow_content })
              end
              assembly_ref_pointer.merge!('task_template' => DBUpdateHash.new(workflows_db_update_hash).mark_as_complete)
            end

            assembly_attrs_db_update_hash = Assembly::Attributes.db_update_hash(parsed_assembly.val(:Attributes) || [])
            assembly_ref_pointer.merge!('attribute' => assembly_attrs_db_update_hash.mark_as_complete)

            tags = get_assembly_tags(parsed_assembly)
            assembly_ref_pointer.merge!('tags' => tags)

            nodes_db_update_hash = Assembly::Nodes.db_update_hash(@container_idh, assembly_ref, parsed_assembly, @component_module_refs, module_local_params, default_assembly_name: assembly_name)
            @db_updates_assemblies['node'].merge!(nodes_db_update_hash.mark_as_complete)

            @ndx_assembly_hashes[assembly_ref] ||= parsed_assembly
          end

          private

          WORKFLOW_TO_TASK_NAMES = {
            'create' => '__create_action'
          }
          def task_action_name(workflow_name)
            WORKFLOW_TO_TASK_NAMES[workflow_name] || workflow_name
          end

          def get_assembly_tags(parsed_assembly)
            parsed_assembly.val(:Target) ? ['target'] : []
          end
          
        end
      end
    end
  end
end
