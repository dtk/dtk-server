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
      def initialize(project, module_branch)
        service_module = module_branch.get_module
        module_refs = ModuleRefs.get_component_module_refs(module_branch)
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

          service_module.create_ec2_properties?(hash_content)
          service_module.parse_assembly_wide_components!(hash_content)

          process(service_module.module_name, hash_content, opts)
          SetParsedDSL.set_assembly_raw_hash?(assembly_name, hash_content, opts)
        end

        assembly_workflows = impor

        module_refs = ModuleRefs.get_component_module_refs(module_branch)
        SetParsedDSL.set_module_refs_and_workflows?(service_module.module_name, assembly_workflows, module_refs)
      end

    end
  end
end
