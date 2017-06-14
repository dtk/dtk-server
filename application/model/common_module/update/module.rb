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
        @project      = project
        @commit_sha   = commit_sha
        @local_params = local_params
        
        #dynamically computed
        @module_branch = nil # common module branch
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

        module_obj, repo = get_module_obj_and_repo
        @module_branch = get_common_module__module_branch(module_obj)

        return ret if @module_branch.is_set_to_sha?(@commit_sha)

        pull_opts = { force: true, install_on_server: opts[:install_on_server] }
        @module_branch.pull_repo_changes_and_return_diffs_summary(@commit_sha, pull_opts) do |repo_diffs_summary|
          if !repo_diffs_summary.empty? || opts[:force_parse]
            @module_branch.set_dsl_parsed!(false)
            if opts[:install_on_server]
              top_dsl_file_changed = true
            else
              ret.add_diffs_summary!(repo_diffs_summary)
              top_dsl_file_changed = repo_diffs_summary.prune!(TOP_DSL_FILE_REGEXP)
            end

            # TODO: make more efficient by just computing parsed_common_module if parsing
            parsed_common_module = dsl_file_obj_from_repo.parse_content(:common_module)
            CommonDSL::Parse.set_dsl_version!(@module_branch, parsed_common_module)
            parse_needed = (opts[:force_parse] == true or top_dsl_file_changed)
            
            unless opts[:skip_missing_check]
              missing_dependencies = check_for_missing_dependencies(parsed_common_module, repo, initial_update: opts[:initial_update])
              if missing_dependencies && missing_dependencies[:missing_dependencies]
                if existing_diffs = ret[:diffs]
                  (missing_dependencies||{}).merge!(existing_diffs: existing_diffs) unless existing_diffs.empty?
                end
                return missing_dependencies
              end
            end

            create_or_update_opts = {
              parse_needed: parse_needed,
              diffs_summary: repo_diffs_summary,
              initial_update: opts[:initial_update]
            }
            create_or_update_from_parsed_common_module(parsed_common_module, repo, create_or_update_opts)
            @module_branch.set_dsl_parsed!(true)
          end
          # This sets sha on branch only after all processing goes through
          @module_branch.update_current_sha_from_repo!
        end
        ret
      end

      TOP_DSL_FILE_REGEXP = CommonDSL::FileType::CommonModule::DSLFile::Top.regexp 

      private

      # returns [module_obj, repo]
      def get_module_obj_and_repo
        local = @local_params.create_local(@project)
        module_obj = self.class.module_exists?(@project.id_handle, local[:module_name], local[:namespace])
        repo = module_obj.get_repo
        repo.merge!(branch_name: local.branch_name)
        [module_obj, repo]
      end

      def get_common_module__module_branch(module_obj)
        namespace_obj = Namespace.find_by_name(@project.model_handle(:namespace), @local_params.namespace)
        module_branch = self.class.get_workspace_module_branch(@project, @local_params.module_name, @local_params.version, namespace_obj)
      end

      def dsl_file_obj_from_repo
        CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(@module_branch) || fail(Error, "Unexpected that 'dsl_file_obj' is nil")
      end

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update
      def create_or_update_from_parsed_common_module(parsed_common_module, repo, opts = {})
        args    = args_for_create_or_update(parsed_common_module, repo, opts)
        retried = false
        # Component info must be loaded before service info because assemblies can have dependencies its own componnets
        begin
          create_or_update_component_info(args)
          create_or_update_service_info(args) unless retried
        rescue ModuleDSL::ParsingError::RefComponentTemplates => exception
          # if trying to delete components from component info that are deleted from assemblies but not processed
          # it will raise RefComponentTemplates; then we want to first process assemblies and retry component_defs processing
          raise exception if retried
          create_or_update_service_info(args)
          retried = true
          retry
        end
      end

      # opts can have keys: 
      #   :initial_update
      def check_for_missing_dependencies(parsed_common_module, repo, opts = {})
        info_service_object(args_for_create_or_update(parsed_common_module, repo, opts)).check_for_missing_dependencies
      end

      def create_or_update_component_info(args)
        Info::Component.new(*args).create_or_update_from_parsed_common_module?
      end

      def create_or_update_service_info(args)
        info_service_object(args, component_defs_exist: Info::Component.component_defs_exist?(args.parsed_common_module)).create_or_update_from_parsed_common_module?
      end

      # opts can have keys
      #   :component_defs_exist
      def info_service_object(args, opts = {})
        Info::Service.new(*(args + [{ component_defs_exist: opts[:component_defs_exist]}]))
      end

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update
      def args_for_create_or_update(parsed_common_module, repo, opts = {})  
        ArgsForCreateOrUpdate.new([@project, @local_params, repo, @module_branch, parsed_common_module, opts])
      end
      class ArgsForCreateOrUpdate < ::Array
        def parsed_common_module
          self[4]
        end
      end
      
    end
  end
end
