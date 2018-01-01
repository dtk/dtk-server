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
    class Module < self
      require_relative('module/info')
      require_relative('module/update_response')

      attr_reader :project
      
      def initialize(project, commit_sha, local_params)
        @project           = project
        @commit_sha        = commit_sha
        @local_params      = local_params
        @module_obj, @repo = get_module_obj_and_repo(local_params, project)
      end
      private :initialize

      # opts can have keys
      #   :force_parse - Boolean (default false) 
      #   :skip_missing_check - Boolean (default false) 
      #   :initial_update - Boolean (default false) 
      def self.update_from_repo(project, commit_sha, local_params, opts = {})
        new(project, commit_sha, local_params).update_from_repo(opts)
      end
      def update_from_repo(opts = {})
        ret = UpdateResponse.new

        return ret if self.module_branch.is_set_to_sha?(self.commit_sha)
        self.module_branch.pull_repo_changes_and_return_diffs_summary(self.commit_sha, force: true) do |repo_diffs_summary|
          if !repo_diffs_summary.empty? || opts[:force_parse] || opts[:initial_update]
            ret.add_diffs_summary!(repo_diffs_summary)

            self.module_branch.set_dsl_parsed!(false)
            CommonDSL::Parse.set_dsl_version!(self.module_branch, self.parsed_common_module)

            parse_needed = (top_dsl_file_changed?(repo_diffs_summary) or opts[:initial_update] or opts[:force_parse])

            # TODO: DTK-2266: Not sure if we need below since later check 
            #  'The components (base_5::c1, child_3::c2) that are referenced by the assembly are not installed' wil find it. Also
            # missing_dependencies is wrong param to ModuleDSL::ParsingError::MissingFromModuleRefs
            #
            # unless opts[:skip_missing_check]
            #  if missing_dependencies = missing_dependencies?(initial_update: opts[:initial_update])
            #    fail ModuleDSL::ParsingError::MissingFromModuleRefs.new(modules: missing_dependencies)
            #  end
            # end

            create_or_update_opts = {
              parse_needed: parse_needed,
              diffs_summary: repo_diffs_summary,
              initial_update: opts[:initial_update]
            }
            create_or_update_from_parsed_common_module(create_or_update_opts)
          end
          self.module_branch.set_dsl_parsed!(true)
          # This sets sha on branch only after all processing goes through
          self.module_branch.update_current_sha_from_repo!
        end
        ret
      end


      attr_reader :project, :local_params, :repo

      def module_branch    
        @module_branch ||= get_module_branch
      end

      def parsed_common_module 
        @parsed_common_module ||= parsed_dsl_from_repo(:common_module)
      end

      def parsed_dependent_modules
        @parsed_dependent_modules ||= parsed_dsl_from_repo(:module_refs_lock, no_file_is_ok: true) || CommonDSL::Parse::FileParser::Output.create(:output_type => :array)
      end

      protected 
      
      attr_reader :commit_sha, :module_obj


      private

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update
      def create_or_update_from_parsed_common_module(opts = {})
        retried = false
        # Component info must be loaded before service info because assemblies can have dependencies its own componnets
        begin
          create_or_update_component_info(opts)
          create_or_update_service_info(opts) unless retried
        rescue ModuleDSL::ParsingError::RefComponentTemplates => exception
          # if trying to delete components from component info that are deleted from assemblies but not processed
          # it will raise RefComponentTemplates; then we want to first process assemblies and retry component_defs processing
          raise exception if retried
          create_or_update_service_info(opts)
          retried = true
          retry
        end
      end

      # returns [module_obj, repo]
      def get_module_obj_and_repo(local_params, project)
        local = local_params.create_local(project)
        module_obj = self.class.module_exists?(project.id_handle, local[:module_name], local[:namespace])
        repo = module_obj.get_repo
        repo.merge!(branch_name: local.branch_name)
        [module_obj, repo]
      end

      def get_module_branch
        namespace_obj = Namespace.find_by_name(self.project.model_handle(:namespace), self.local_params.namespace)
        self.class.get_workspace_module_branch(self.project, self.local_params.module_name, self.local_params.version, namespace_obj)
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
      #   :initial_update
      def missing_dependencies?(opts = {})
        Info::Service.new(self, initial_update: opts[:initial_update]).missing_dependencies?
      end

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update  
      def create_or_update_service_info(opts = {})
        component_defs_exist = Info::Component.component_defs_exist?(self.parsed_common_module)
        Info::Service.new(self, opts.merge(component_defs_exist: component_defs_exist)).create_or_update_from_parsed_common_module?
      end

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update  
      def create_or_update_component_info(opts = {})
        Info::Component.new(self, opts).create_or_update_from_parsed_common_module?(opts.merge(use_new_snapshot: true))
      end
      
    end
  end
end
