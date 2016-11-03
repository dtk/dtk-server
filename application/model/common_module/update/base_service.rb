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
    class Update
      class BaseService < self
        # opts can have keys
        #   :local_params (required)
        #   :repo_name (required)
        #   :force_pull - Boolean (default false) 
        #   :force_parse - Boolean (default false) 
        def self.update_from_repo(project, commit_sha, opts = {})
          unless repo_name = opts[:repo_name]
            fail Error, "opts[:repo_name] should not be nil"
          end
          unless local_params = opts[:local_params]
            fail Error, "opts[:local_params] should not be nil"
          end
          # for testing
          opts[:force_parse] = opts[:force_pull] = true

          local             = local_params.create_local(project)
          local_branch      = local.branch_name
  
          module_obj = module_exists?(project.id_handle(), local[:module_name], local[:namespace])
          repo = module_obj.get_repo
          repo.merge!(branch_name: local_branch)
          repo_user_acls = RepoUser.authorized_users_acls(project.id_handle())
          create_opts = {
            donot_create_master_branch: true,
            delete_if_exists: true
          }
          repo_with_branch = repo.create_subclass_obj(:repo_with_branch)
          
          ret = ModuleDSLInfo.new
          common_module__module_branch, pull_was_needed = pull_repo_changes?(project, local_params, commit_sha, opts)
          parse_needed = (opts[:force_parse] || !common_module__module_branch.dsl_parsed?)
          return ret unless parse_needed || pull_was_needed

          remote_params = ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
            module_type: local_params[:module_type],
            module_name: local_params[:module_name],
            namespace: local_params[:namespace],
            remote_repo_base: RepoRemote.repo_base
          )

          repo_with_branch.merge!(ref: repo_with_branch[:display_name])
          remote = remote_params.create_remote(project)
          create_repo_remote_object(repo_with_branch, remote, opts[:repo_name])

          parsed_common_module = dsl_file_obj_from_repo(common_module__module_branch).parse_content(:common_module)
          CommonDSL::Parse.set_dsl_version!(common_module__module_branch, parsed_common_module)
          create_or_update_from_parsed_common_module(project, local_params, common_module__module_branch, parsed_common_module)
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

        def self.create_or_update_from_parsed_common_module(project, local_params, common_module__module_branch, parsed_common_module)
          module_branch = create_or_ret_module_branch(:service_module, project, local_params, common_module__module_branch)
          CommonDSL::Parse.set_dsl_version!(module_branch, parsed_common_module)
          update_component_module_refs_from_parsed_common_module(module_branch, parsed_common_module)
          CommonModule::BaseService.update_assemblies_from_parsed_common_module(project, module_branch, parsed_common_module)
        end

        # if module does not exist, create it
        # else if module branch does not exist, create it
        # else return module branch
        def self.create_or_ret_module_branch(type, project, common_module__local_params, common_module__module_branch)
          module_name    = common_module__local_params.module_name
          namespace_name = common_module__local_params.namespace
          local_params = create_local_params(type, module_name, version: common_module__module_branch[:version], namespace: namespace_name)
          
          namespace = Namespace.find_by_name(project.model_handle(:namespace), namespace_name)
          version   = local_params.version
          module_class = get_class_from_type(type)
          
          if service_module = module_class.find_from_name?(project.model_handle(type), namespace_name, module_name)
            if module_branch = module_class.get_workspace_module_branch(project, module_name, version, namespace, no_error_if_does_not_exist: true)
              module_branch
            else
              repo = service_module.get_repo
              module_branch = module_class.create_ws_module_and_branch_obj?(project, repo.id_handle, module_name, version, namespace, return_module_branch: true)
              repo.merge!(branch_name: module_branch[:branch])
              RepoManager.add_branch_and_push?(module_branch[:branch], { empty: true }, module_branch)
              module_branch
            end
          else
            module_class.create_module(project, local_params, return_module_branch: true)
          end
        end

        def self.update_component_module_refs_from_parsed_common_module(module_branch, parsed_common_module)
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

        private

        def self.dsl_file_obj_from_repo(module_branch)
          CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(module_branch) || fail(Error, "Unexpected that 'dsl_file_obj' is nil")
        end
        
      end
    end
  end
end
