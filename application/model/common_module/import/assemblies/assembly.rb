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
  class CommonModule::Import::Assemblies
    module AssemblyMixin
      # opts can have keys:
      #   :module_version
      def process_assembly!(parsed_assembly, opts = {})
        @assembly_name = parsed_assembly.req(:AssemblyName)
        @assembly_ref = @service_module.assembly_ref(@assembly_name, opts[:module_version])
        # Aldin: 06/27/2016: remove need for version_proc_class  and instaed handle anything dsl version specfic in
        # dtk-dsl
        # in process_assembly_top! and process_assembly_body!
        # rversion_proc_class.import_assembly_top and version_proc_class.import_nodes
        # should be replaced by two phase processing:
        # dtk-dsl should do fine grain parsing of assembly rather than course (i.e., returning just :name and :assembly
        # This should return hash with all keys in 'symbol form' we then have code in dtk-server that converts this to
        #  'db_update_hash form' and adds anything that needs db lookup such as the ids'
        #  if having parsed_assemblies using symbol rather than string keys forces much rewrite on part of code that
        #  converts to 'db_update_hash form' then we could either return rather than a class that inherots from hash
        #  that allows one to interchange between strings an dkeys; I got pretty far in writing this but had some problems
        #  so left this as a branch in dtk-dsl: https://github.com/dtk/dtk-dsl/tree/common_input_output
        # in the version_proc_class when see 'aggregate_errors.aggregate_errors!'; remove this; its purpose is to bulk up errors
        # to make parsing simpler just throwing error on first error
        integer_version = 4 # stubbed this until we remove version_proc_class
        @version_proc_class = load_and_return_version_adapter_class(integer_version)

        process_assembly_top!(parsed_assembly)
        process_assembly_body!(parsed_assembly)

        # Aldin: 06/27/2016: See if these can be removed
        @ndx_assembly_hashes[@assembly_ref] ||= parsed_assembly
        @ndx_version_proc_classes[@assembly_ref] ||= @version_proc_class
      end

      private

      def process_assembly_top!(parsed_assembly)
        db_updates_cmp = @version_proc_class.import_assembly_top(@assembly_ref, parsed_assembly, @module_branch, @module_name, default_assembly_name: @assembly_name)
        @db_updates_assemblies['component'].merge!(db_updates_cmp)
      end

      def process_assembly_body!(parsed_assembly)
        # if bad node reference, return error and continue with module import
        # Took at processing of node_bidnings_hash since assume common modules have node attributes instaed
        node_bindings_hash = {}
        db_updates = @version_proc_class.import_nodes(@container_idh, @module_branch, @assembly_ref, parsed_assembly, node_bindings_hash, @component_module_refs, default_assembly_name: @assembly_name)
        raise db_updates if ServiceModule::ParsingError.is_error?(db_updates)
        @db_updates_assemblies['node'].merge!(db_updates)
      end
    end
  end
end
