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
    class AssembliesImportHelper < ServiceModule::AssemblyImport
      def initialize(project, service_module, module_branch)
        module_refs   = ModuleRefs.get_component_module_refs(module_branch)
        @parent_class = service_module.class
        super(project.id_handle, module_branch, service_module, module_refs)
      end

      def process_from_parse_hash(parse_hash)
        parse_hash.each do |assembly|
          hash_content     = {}
          assembly_name    = assembly[:name]
          assembly_content = assembly[:content]
          opts             = { default_assembly_name: assembly_name }

          if workflows = assembly_content && assembly_content.delete('workflows')
            hash_content.merge!('workflows' => workflows)
          end

          hash_content.merge!('assembly' => assembly_content)

          # hash_content.merge!('dsl_version' => '1.0.0')
          # TODO: Aldin - need to take dsl_version from hash;
          # currently there is issue with using version 1.0.0, error happens in
          # application/model/module/service_module/dsl/assembly_import/adapters/v4.rb:79:in `import_task_templates'",
          # so when dsl_version not specified it will use old v2 adapter and it will pass successfully

          hash_content.merge!('name' => assembly_name)

          @service_module.create_ec2_properties?(hash_content)
          @service_module.parse_assembly_wide_components!(hash_content)

          process_assembly(hash_content, opts)
          @parent_class::SetParsedDSL.set_assembly_raw_hash?(assembly_name, hash_content, opts)
        end

        assembly_workflows = import

        @parent_class::SetParsedDSL.set_module_refs_and_workflows?(@module_name, assembly_workflows, @component_module_refs)
      end

      private

      def process_assembly(assembly_hash, opts = {})
        assembly_ref = @service_module.assembly_ref(assembly_hash['name'], opts[:module_version])
        assembly_content = (assembly_hash['assembly'] || {}).merge(Aux.hash_subset(assembly_hash, ['name', 'description', 'workflow']))
        # Aldin: 02/24/2016: want to remove need for version_proc_class and handle the version sepcfic parsing in dtk-dsl
        integer_version = determine_integer_version(assembly_hash, opts)
        version_proc_class = load_and_return_version_adapter_class(integer_version)


        db_updates_cmp = version_proc_class.import_assembly_top(assembly_ref, assembly_content, @module_branch, @module_name, opts)
        @db_updates_assemblies['component'].merge!(db_updates_cmp)

        # if bad node reference, return error and continue with module import
        imported_nodes = version_proc_class.import_nodes(@container_idh, @module_branch, assembly_ref, assembly_content, node_bindings_hash, @component_module_refs, opts)
        raise imported_nodes if ParsingError.is_error?(imported_nodes)

        @db_updates_assemblies['node'].merge!(imported_nodes)
        @ndx_assembly_hashes[ref] ||= assem
        @ndx_version_proc_classes[ref] ||= version_proc_class
      end
    end
  end
end
