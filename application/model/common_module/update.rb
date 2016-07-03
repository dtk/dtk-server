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
    class Update < self
      require_relative('update/base_service')
#      require_relative('update/base_component')
#      require_relative('update/service_instance')

      def self.update_class(common_module_type)
        case common_module_type
        when :base_service then BaseService
        when :base_component then BaseComponent
        when :_service_instance then ServiceInstance
        else fail Error, "Illegal common_module_type '#{common_module_type}'"
        end
      end

      # opts can have keys
      #   :force_pull - Boolean (default false) 
      #   :force_parse - Boolean (default false) 
      def self.update_from_repo(project, local_params, repo_name, commit_sha, opts = {})
# for testing
opts[:force_parse] = opts[:force_pull] = true

        ret = ModuleDSLInfo.new
        module_branch, pull_was_needed = pull_repo_changes?(project, local_params, commit_sha, opts)
        parse_needed = (opts[:force_parse] || !module_branch.dsl_parsed?)
        return ret unless parse_needed || pull_was_needed

        parsed_common_module = dsl_file_obj_from_repo(module_branch).parse_content(:common_module)
        pp [:debug, :parsed_common_module, parsed_common_module]
        create_or_update_from_parsed_common_module(project, local_params, module_branch, parsed_common_module)
        ret
      end

      private

      # returns [module_branch, pull_was_needed]
      def self.pull_repo_changes?(project, local_params, commit_sha, opts = {})
        namespace = Namespace.find_by_name(project.model_handle(:namespace), local_params.namespace)
        module_branch = get_workspace_module_branch(project, local_params.module_name, local_params.version, namespace)
        pull_was_needed = module_branch.pull_repo_changes?(commit_sha, opts[:force_pull])
        [module_branch, pull_was_needed]
      end

      def self.dsl_file_obj_from_repo(module_branch)
        DSL::Parse.matching_common_module_file_obj?(module_branch) || fail(Error, "Unexpected that 'dsl_file_obj' is nil")
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
          if module_branch = module_class.get_workspace_module_branch(project, module_name, version, namespace)
            module_branch
          else
            repo = service_module.get_repo
            module_class.create_ws_module_and_branch_obj?(project, repo.id_handle, module_name, version, namespace, nil, return_module_branch: true)
          end
        else
          module_class.create_module(project, local_params, return_module_branch: true)
        end
      end
    end
  end
end
