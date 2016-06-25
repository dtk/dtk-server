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

      def put_needed_info_into_import_helper!(parse_hash)
        parse_hash.each do |assembly|
          hash_content     = {}
          assembly_name    = assembly.req(:AssemblyName)
          # TODO: content wil be replaced by finer grain parsed objects
          assembly_content = assembly[:content]
          opts             = { default_assembly_name: assembly_name }

          if workflows = assembly_content && assembly_content.delete('workflows')
            hash_content.merge!('workflows' => workflows)
          end

          hash_content.merge!('assembly' => assembly_content)

          # Aldin: 06/24/2016: no need to pass in dsl version; since parse_hash wil reflect all teh vesrion specific parsing and be
          # in version independent 'canonical form'
          # I put back in hash_content.merge!('dsl_version' => '1.0.0') so the code runs through v4 parsing
          # all the equivalent rules to v4 parsing should be put in dtk-dsl under v1
          hash_content.merge!('dsl_version' => '1.0.0')
          # TODO: Aldin - need to take dsl_version from hash;
          # currently there is issue with using version 1.0.0, error happens in
          # application/model/module/service_module/dsl/assembly_import/adapters/v4.rb:79:in `import_task_templates'",
          # so when dsl_version not specified it will use old v2 adapter and it will pass successfully

          hash_content.merge!('name' => assembly_name)

          @service_module.create_ec2_properties?(hash_content)
          @service_module.parse_assembly_wide_components!(hash_content)

          process_assembly(hash_content, opts)
          # TODO: dont need unless have opts[:ret_parsed_dsl] is set to true
          # @parent_class::SetParsedDSL.set_assembly_raw_hash?(assembly_name, hash_content, opts)
        end
      end

      def import_into_model
        import
      end

      private

      def process_assembly(assembly_hash, opts = {})
        assembly_ref = @service_module.assembly_ref(assembly_hash['name'], opts[:module_version])
        assembly_content = (assembly_hash['assembly'] || {}).merge(Aux.hash_subset(assembly_hash, ['name', 'description', 'workflow']))
        # Aldin: 06/24/2016: remove need for version_proc_class  and instaed handle anything dsl version specfic in
        # dtk-dsl
        # version_proc_class.import_assembly_top and version_proc_class.import_nodes
        # should be replaced by two phase processing:
        # dtk-dsl should do fine grain parsing of assembly rather than course (i.e., returning just :name and :assembly
        # This should return hash with all keys in 'symbol form' we then have code in dtk-server that converts this to
        #  'db_update_hash form' and adds anything that needs db lookup such as the ids'
        #  if having parse_hash using symbol rather than string keys forces much rewrite on part of code that
        #  converts to 'db_update_hash form' then we could either return rather than a class that inherots from hash
        #  that allows one to interchange between strings an dkeys; I got pretty far in writing this but had some problems
        #  so left this as a branch in dtk-dsl: https://github.com/dtk/dtk-dsl/tree/common_input_output
        # in the version_proc_class when see 'aggregate_errors.aggregate_errors!'; remove this; its purpose is to bulk up errors
        # to make parsing simpler just throwing error on first error
        integer_version = determine_integer_version(assembly_hash, opts)
        version_proc_class = load_and_return_version_adapter_class(integer_version)

        db_updates_cmp = version_proc_class.import_assembly_top(assembly_ref, assembly_content, @module_branch, @module_name, opts)
        @db_updates_assemblies['component'].merge!(db_updates_cmp)

        # if bad node reference, return error and continue with module import
        # Took at processing of node_bidnings_hash since assume common modules have node attributes instaed
        node_bindings_hash = {}
        imported_nodes = version_proc_class.import_nodes(@container_idh, @module_branch, assembly_ref, assembly_content, node_bindings_hash, @component_module_refs, opts)
        raise imported_nodes if ServiceModule::ParsingError.is_error?(imported_nodes)

        @db_updates_assemblies['node'].merge!(imported_nodes)

        # Aldin: 06/24/2016: See if these can be removed
        @ndx_assembly_hashes[assembly_ref] ||= assembly_content
        @ndx_version_proc_classes[assembly_ref] ||= version_proc_class
      end
    end
  end
end
