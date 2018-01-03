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
  class CommonModule::Update::Module::Info
    class Component < self
      require_relative('component/transform')

      def create_or_update_from_parsed_common_module?(opts = {})
        return unless module_info_exists?
        CommonDSL::Parse.set_dsl_version!(self.component_module_branch, self.parsed_common_module)
        update_component_info_in_model_from_dsl(opts) if parse_needed?
      end

      def self.component_defs_exist?(parsed_common_module)
        !parsed_common_module.val(:ComponentDefs).nil?
      end

      def self.module_info_exists?(parsed_common_module)
        # second clause is to handle modules without any components
        component_defs_exist?(parsed_common_module) or parsed_common_module.val(:Assemblies).nil?
      end

      protected

      def component_module_branch 
        @component_module_branch ||= create_module_and_branch?(create_implementation: true)
      end

      def aug_component_module_branch
        @aug_component_module_branch ||= self.component_module_branch.augmented_module_branch.augment_with_component_module!
      end

      def parsed_compoinent_defs
        @parsed_compoinent_defs ||= parsed_nested_object(:ComponentDefs)
      end

      def module_type
        :component_module
      end

      private

      def module_info_exists?
        self.class.module_info_exists?(self.parsed_common_module)
      end

      # TODO: DTK-2766: this uses the legacy parsing routines in the dtk-server gem. Port over to dtk-dsl parsing
      # opts can have keys
      #   :use_new_snapshot
      def update_component_info_in_model_from_dsl(opts = {})
        aug_mb = self.aug_component_module_branch # alias
        # TODO: for migration purposes needed the  Implementation.create? method. This shoudl be done during initial create
        impl = aug_mb.get_implementation? || Implementation.create?(self.project, self.local_params, aug_mb.repo)
        parse_opts = {
          dsl_created_info: dsl_created_info,
          donot_update_module_refs: true,
          use_new_snapshot: opts[:use_new_snapshot]
        }
        if parsed_dependent_modules
          parse_opts.merge!(dependent_modules: (self.parsed_dependent_modules || []).map { |dependent_module| dependent_module.req(:ModuleName) })
        end
        response = aug_mb.component_module.parse_dsl_and_update_model(impl, aug_mb.id_handle, self.version, parse_opts)
        fail response if ModuleDSL::ParsingError.is_error?(response)
      end

      COMPONENT_YAML_FILENAME = 'dtk.model.yaml'
      def dsl_created_info
        transform = Transform.new(self.parsed_common_module, self).compute_component_module_outputs!
        content = transform.output_path_hash_pairs[COMPONENT_YAML_FILENAME] || fail(Error, "Unexpected that '#{COMPONENT_YAML_FILENAME}' not found")
        {
          path: COMPONENT_YAML_FILENAME,
          content: content
        }
      end

      #TODO: is this needed?
      def dependent_modules

      end


    end
  end
end

