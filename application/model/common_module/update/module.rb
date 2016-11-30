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
      require_relative('module/service_info')
      # require_relative('module/component_info')

      # opts can have keys
      #   :local_params (required)
      #   :repo_name (required)
      #   :force_pull - Boolean (default false) 
      #   :force_parse - Boolean (default false) 
      def self.update_from_repo(project, commit_sha, opts = {})
        ret = ModuleDSLInfo.new

        repo_name    = opts[:repo_name] || fail(Error, "opts[:repo_name] should not be nil")
        local_params = opts[:local_params] || fail(Error, "opts[:local_params] should not be nil")

        # TODO: should we remove
        opts[:force_parse] = opts[:force_pull] = true # for testing
        
        local             = local_params.create_local(project)
        local_branch      = local.branch_name
        
        module_obj = module_exists?(project.id_handle, local[:module_name], local[:namespace])
        repo = module_obj.get_repo
        repo.merge!(branch_name: local_branch)
        
        RepoUser.authorized_users_acls(project.id_handle)
        
        common_module__module_branch, pull_was_needed = pull_repo_changes?(project, local_params, commit_sha, force_pull: opts[:force_pull])
        parse_needed = (opts[:force_parse] || !common_module__module_branch.dsl_parsed?)
        return ret unless parse_needed || pull_was_needed
        
        create_common_module_repo_remote(project, local_params, repo, repo_name: opts[:repo_name])

        parsed_common_module = dsl_file_obj_from_repo(common_module__module_branch).parse_content(:common_module)
        CommonDSL::Parse.set_dsl_version!(common_module__module_branch, parsed_common_module)
        
        create_or_update_from_parsed_common_module(project, local_params, common_module__module_branch[:version], parsed_common_module)
        ret
      end

      private

      # opts can have keys:
      #   :force_pull
      def self.pull_repo_changes?(project, local_params, commit_sha, opts = {})
        namespace = Namespace.find_by_name(project.model_handle(:namespace), local_params.namespace)
        module_branch = get_workspace_module_branch(project, local_params.module_name, local_params.version, namespace)
        pull_was_needed = module_branch.pull_repo_changes?(commit_sha, force: opts[:force_pull])
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
      
      def self.create_or_update_from_parsed_common_module(project, local_params, module_version, parsed_common_module)
        ServiceInfo.new(project, local_params, module_version, parsed_common_module).create_or_update_from_parsed_common_module?
        # ComponentInfo.new(project, local_params, module_version, parsed_common_module).create_or_update_from_parsed_common_module?
      end

      # instance methods; used by children ServiceInfo and ComponentInfo

      attr_reader :project, :module_name, :namespace_name, :version, :local_params, :parsed_common_module, :module_class
      def initialize(project, common_module__local_params, module_version, parsed_common_module)
        @project              = project
        @module_name          = common_module__local_params.module_name
        @namespace_name       = common_module__local_params.namespace
        @version              = module_version
        @local_params         = self.class.create_local_params(module_type, @module_name, version: @version, namespace: @namespace_name)
        @parsed_common_module = parsed_common_module
        @module_class         = self.class.get_class_from_module_type(module_type)
      end

      # if module does not exist, create it
      # else if module branch does not exist, create it
      # else return module branch
      def create_or_ret_module_branch
        if module_obj = module_class.find_from_name?(project.model_handle(module_type), namespace_name, module_name)
          namespace_obj = Namespace.find_by_name(project.model_handle(:namespace), namespace_name)
          if module_branch = module_class.get_workspace_module_branch(project, module_name, version, namespace_obj, no_error_if_does_not_exist: true)
            module_branch
          else
            repo = module_obj.get_repo
            module_branch = module_class.create_ws_module_and_branch_obj?(project, repo.id_handle, module_name, version, namespace_obj, return_module_branch: true)
            repo.merge!(branch_name: module_branch[:branch])
            RepoManager.add_branch_and_push?(module_branch[:branch], { empty: true }, module_branch)
            module_branch
          end
        else
          module_class.create_module(project, local_params, return_module_branch: true)
        end
      end

      def update_component_module_refs_from_parsed_common_module(module_branch)
        if dependent_modules = parsed_common_module.val(:DependentModules)
          component_module_refs = ModuleRefs.get_component_module_refs(module_branch)

          cmp_modules_with_namespaces = dependent_modules.map do |parsed_module_ref|
            { 
              display_name: parsed_module_ref.req(:ModuleName), 
              namespace_name: parsed_module_ref.req(:Namespace), 
              version_info: parsed_module_ref.val(:ModuleVersion) 
            }
          end
          
          component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
        end
      end

    end
  end
end
