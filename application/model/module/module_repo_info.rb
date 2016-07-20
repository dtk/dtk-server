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
  class ModuleRepoInfo < ::Hash
    def initialize(repo, module_name, module_idh, branch_obj, opts = {})
      super()
      repo_name = repo.get_field?(:repo_name)
      module_namespace =  opts[:module_namespace]
      full_module_name = module_namespace ? Namespace.join_namespace(module_namespace, module_name) : nil
      hash = {
        repo_id: repo[:id],
        repo_name: repo_name,
        module_id: module_idh.get_id(),
        module_name: module_name,
        module_namespace: module_namespace,
        full_module_name: full_module_name,
        module_branch_idh: branch_obj.id_handle(),
        repo_url: RepoManager.repo_url(repo_name),
        workspace_branch: branch_obj.get_field?(:branch),
        branch_head_sha: RepoManager.branch_head_sha(branch_obj),
        frozen: branch_obj[:frozen]
      }

      if version = opts[:version]
        hash.merge!(version: version)
        if assembly_name = version.respond_to?(:assembly_name) && version.assembly_name()
          hash.merge!(assembly_name: assembly_name)
        end
      end

      hash.merge!(merge_warning_message: opts[:merge_warning_message]) if opts[:merge_warning_message]
      replace(hash)
    end
  end

  class CloneUpdateInfo < ModuleRepoInfo
    def initialize(module_obj, version = nil)
      aug_branch = module_obj.get_augmented_workspace_branch(filter: { version: version })
      opts = { version: version, module_namespace: module_obj.module_namespace() }
      opts.merge!(merge_warning_message: module_obj[:merge_warning_message]) if module_obj[:merge_warning_message]
      super(aug_branch[:repo], aug_branch[:module_name], module_obj.id_handle(), aug_branch, opts)
      self[:commit_sha] = aug_branch[:current_sha]
    end
  end
end
