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
      require_relative('module/mixin')
      require_relative('module/update_info')
      require_relative('module/service_info')
      require_relative('module/component_info')

      include Mixin

      # opts can have keys
      #   :local_params (required)
      #   :repo_name (required)
      #   :force_pull - Boolean (default false) 
      #   :force_parse - Boolean (default false) 
      def self.update_from_repo(project, commit_sha, opts = {})
        ret = UpdateInfo.new

        repo_name    = opts[:repo_name] || fail(Error, "opts[:repo_name] should not be nil")
        local_params = opts[:local_params] || fail(Error, "opts[:local_params] should not be nil")

        local             = local_params.create_local(project)
        local_branch      = local.branch_name

        module_obj = module_exists?(project.id_handle, local[:module_name], local[:namespace])
        repo = module_obj.get_repo
        repo.merge!(branch_name: local_branch)

        # update_dsl_parsed is set so that common_module__module_branch will have dsl_parsed set to false if a dsl file is changed
        pull_opts = { 
          ret_diffs: nil, # means to return diffs
          force_pull: opts[:force_pull], 
          update_dsl_parsed: CommonDSL::FileType::CommonModule::DSLFile::Top.regexp 
        }
        common_module__module_branch, pull_was_needed = pull_repo_changes?(project, local_params, commit_sha, pull_opts)
        ret.add_diffs!(pull_opts[:ret_diffs])

        parse_needed = (opts[:force_parse] || !common_module__module_branch.dsl_parsed?)
        return ret unless parse_needed || pull_was_needed
        
        create_common_module_repo_remote(project, local_params, repo, repo_name: opts[:repo_name])

        parsed_common_module = dsl_file_obj_from_repo(common_module__module_branch).parse_content(:common_module)
        CommonDSL::Parse.set_dsl_version!(common_module__module_branch, parsed_common_module)

        create_or_update_from_parsed_common_module(project, local_params, repo, common_module__module_branch, parsed_common_module, parse_needed: parse_needed)
        common_module__module_branch.set_dsl_parsed!(true)

        ret
      end

      private

      # opts can have keys:
      #   :force_pull
      #   :update_dsl_parsed - if set then regexp that matches dsl file
      #   :ret_diffs - if set then this method will update it with a Repo::Diffs object
      def self.pull_repo_changes?(project, local_params, commit_sha, opts = {})
        namespace = Namespace.find_by_name(project.model_handle(:namespace), local_params.namespace)
        module_branch = get_workspace_module_branch(project, local_params.module_name, local_params.version, namespace)
        pull_opts = {
          force: opts[:force_pull], 
          ret_diffs: opts[:ret_diffs],
          update_dsl_parsed: opts[:update_dsl_parsed]
        }
        pull_was_needed = module_branch.pull_repo_changes?(commit_sha, pull_opts)
        opts[:ret_diffs] = pull_opts[:ret_diffs] if opts.has_key?(:ret_diffs)
        [module_branch, pull_was_needed]
      end

      # opts can have keys:
      #   :repo_name
      def self.create_common_module_repo_remote(project, local_params, repo, opts = {})
        remote_params = ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
          module_type: local_params[:module_type],
          module_name: local_params[:module_name],
          namespace: local_params[:namespace],
          remote_repo_base: RepoRemote.repo_base
        )
        repo_with_branch = repo.create_subclass_obj(:repo_with_branch)
        repo_with_branch.merge!(ref: repo_with_branch[:display_name])

        remote = remote_params.create_remote(project)
        create_repo_remote_object(repo_with_branch, remote, opts[:repo_name])
      end

      def self.dsl_file_obj_from_repo(module_branch)
        CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(module_branch) || fail(Error, "Unexpected that 'dsl_file_obj' is nil")
      end
      
      # args has project, common_module__local_params, common_module__repo, common_module__module_branch, parsed_common_module, opts = {})
      def self.create_or_update_from_parsed_common_module(*args)
        # Component info must be loaded before service info because assemblies can have dependencies its own componnets
        component_info_exists = ComponentInfo.new(*args).create_or_update_from_parsed_common_module?
        ServiceInfo.new(*(args + [{ component_info_exists: component_info_exists }])).create_or_update_from_parsed_common_module?
      end

    end
  end
end
