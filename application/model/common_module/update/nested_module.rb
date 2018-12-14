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
  class CommonModule::Update
    class NestedModule < self
      require_relative('nested_module/update_module_refs')
      require_relative('nested_module/info')
      require_relative('nested_module/update_response')

      include UpdateModuleRefs::Mixin

      attr_reader :project
      
      def initialize(project, commit_sha, local_params, existing_aug_mb)
        @project           = project
        @commit_sha        = commit_sha
        @local_params      = local_params
        @module_obj, @repo = get_module_obj_and_repo(local_params, project, existing_aug_mb.display_name)
        @module_branch     = existing_aug_mb
      end
      private :initialize

      # opts can have keys
      #   :force_parse - Boolean (default false) 
      #   :initial_update - Boolean (default false) 
      def self.update_from_repo(project, commit_sha, local_params, existing_aug_mb, opts = {})
        new(project, commit_sha, local_params, existing_aug_mb).update_from_repo(opts)
      end
      def update_from_repo(opts = {})
        ret = UpdateResponse.new
        #return ret if self.module_branch.is_set_to_sha?(self.commit_sha)
        parse_needed = opts[:initial_update] || opts[:force_parse]
        create_or_update_opts = {
          parse_needed: parse_needed,
          initial_update: opts[:initial_update]
        }
        create_or_update_from_parsed_component_module(create_or_update_opts)
        self.module_branch.set_dsl_parsed!(true)
        # This sets sha on branch only after all processing goes through
        self.module_branch.update_current_sha_from_repo!
        ret
      end

      attr_reader :project, :local_params, :repo

      def module_branch    
        @module_branch ||= get_module_branch
      end

      def parsed_component_module 
        @parsed_component_module ||= parsed_dsl_from_repo(:common_module)
      end

      def parsed_dependent_modules
        @parsed_dependent_modules ||= parsed_dsl_from_repo(:module_refs_lock, no_file_is_ok: true) || CommonDSL::Parse::FileParser::Output.create(:output_type => :array)
      end

      protected 
      
      attr_reader :commit_sha, :module_obj


      private

      # opts can have keys:
      #   :parse_needed
      #   :initial_update
      def create_or_update_from_parsed_component_module(opts = {})
        update_module_refs
        # Component info must be loaded before service info because assemblies can have dependencies its own componnets
        begin
          create_or_update_component_info(opts)
        rescue ModuleDSL::ParsingError::RefComponentTemplates => exception
          raise exception
        end
      end

      # returns [module_obj, repo]
      def get_module_obj_and_repo(local_params, project, branch_name)
        local = local_params.create_local(project, new_branch_name: branch_name)
        module_obj = self.class.module_exists?(project.id_handle, local[:module_name], local[:namespace])
        repo = module_obj.get_repo
        repo.merge!(branch_name: branch_name)
        [module_obj, repo]
      end

      def get_module_branch
       @module_branch
      end

      TOP_DSL_FILE_REGEXPS = [CommonDSL::FileType::CommonModule::DSLFile::Top.regexp, CommonDSL::FileType::ModuleRefsLock::DSLFile::Top.regexp] 

      # This method checks if a top_dsl_file_changed and also prunes these form repo_diffs_summary
      def top_dsl_file_changed?(repo_diffs_summary)
        top_dsl_file_changed = false
        TOP_DSL_FILE_REGEXPS.each do | top_dsl_file_regexp |
          top_dsl_file_changed = true if repo_diffs_summary.prune!(top_dsl_file_regexp)
        end
        top_dsl_file_changed
      end

      #  opts can be keys:
      #    :no_file_is_ok
      def parsed_dsl_from_repo(dsl_type, opts = {})
        if dsl_file_obj = dsl_file_obj_from_repo(dsl_type, opts)
          dsl_file_obj.parse_content(dsl_type)
        end
      end

      def dsl_file_obj_from_repo(dsl_type, opts = {})
        ret = CommonDSL::Parse.matching_dsl_file_obj?(dsl_type, self.module_branch)
        if ret.nil? and ! opts[:no_file_is_ok]
          fail(Error, "Unexpected that dsl_file_obj '#{dsl_type}' is nil")
        end
        ret
      end

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update  
      def create_or_update_component_info(opts = {})
        ::DTK::CommonModule::Update::NestedModule::Info::Component.new(self, opts).create_or_update_from_parsed_component_module?(opts.merge(use_new_snapshot: true))
      end
      
    end
  end
end
