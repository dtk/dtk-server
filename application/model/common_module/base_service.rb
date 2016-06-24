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
    class BaseService < ServiceModule
      extend  CommonModule::ClassMixin
      include CommonModule::Mixin

      def self.find_from_id?(model_handle, module_id)
        get_obj(model_handle, sp_filter(:eq, :id, module_id))
      end

      NS_MOD_DELIM_IN_REF = ':'
      def self.find_from_name?(model_handle, namespace, module_name)
        ref = "#{namespace}#{NS_MOD_DELIM_IN_REF}#{module_name}"
        get_obj(model_handle, sp_filter(:eq, :ref, ref))
      end

      def assembly_template?(assembly_name, version)
        assembly_version   = (version.nil? || version.eql?('base')) ? 'master' : version
        get_assembly_templates.find { |template| template[:display_name] == assembly_name and template[:version] == assembly_version }
      end

      def name_with_namespace
        get_field?(:ref)
      end

      def self.create_empty_module(project, local_params, opts = {})
        opts = opts.merge(return_module_branch: true)
        module_branch = create_module(project, local_params, opts)
        ModuleRepoInfo.new(module_branch)
      end

      def self.update_assemblies_from_parse_hash(project, module_branch, parse_hash)
        if assemblies = parse_hash[:assemblies]
          module_branch.set_dsl_parsed!(false)

          base_service_module = get_base_service_module(module_branch)
          import_helper = AssembliesImportHelper.new(project, base_service_module, module_branch)
          import_helper.put_needed_info_into_import_helper!(assemblies)
          import_helper.import_into_model
          # TODO: dont need set_module_refs_and_workflows?; only applicable if opts passed and
          #  have opts[:ret_parsed_dsl] set to true
          #assembly_workflows = import_helper.import_into_model
          #SetParsedDSL.set_module_refs_and_workflows?(import_helper.module_name, assembly_workflows, import_helper.component_module_refs)

          module_branch.set_dsl_parsed!(true)
        end
      end

      private

      def self.get_base_service_module(module_branch)
        copy_as(module_branch.get_module)
      end

      # This causes all get_obj(s) class an instance methods to return BaseService objects, rather than ServiceModule ones
      def self.get_objs(model_handle, sp_hash, opts = {})
        if model_handle[:model_name] == :service_module
          super.map { |service_module| copy_as(service_module) }
        else
          super
        end
      end
    end
  end
end
