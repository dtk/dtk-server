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
lambda__segment_module_branches =
  lambda do|args|
  ret = {
    model_name: :module_branch,
    convert: true,
    join_type: :inner,
    join_cond: { common_id: :common_module__id },
    cols: args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret
end
lambda__segment_namespace =
  lambda do|args|
  ret = {
    model_name: :namespace,
    convert: true,
    join_type: :inner,
    join_cond: { id: :common_module__namespace_id },
    cols: args[:cols]
  }
  ret
end
lambda__segment_impls =
  lambda do|args|
  ret = {
    model_name: :implementation,
    convert: true,
    join_type: :inner,
    join_cond: { repo_id: :module_branch__repo_id },
    cols: args[:cols]
  }
  ret[:filter] = args[:filter] if args[:filter]
  ret[:alias] = args[:alias] if args[:alias]
  ret
end
lambda__segment_repos =
  lambda do|args|
  {
    model_name: :repo,
    convert: true,
    join_type: :inner,
    join_cond: { id: :module_branch__repo_id },
    cols: args[:cols]
  }
end
{
  schema: :module,
  table: :common,
  columns: {
    dsl_parsed: { type: :boolean, default: false }, #set to true when dsl has successfully parsed
    namespace_id: {
      type: :bigint,
      foreign_key_rel_type: :namespace,
      on_delete: :set_null,
      on_update: :set_null
    }
  },
  virtual_columns: {
    namespace: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_namespace.call(cols: Namespace.common_columns())]
    },
    module_branches: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_module_branches.call(cols: ModuleBranch.common_columns())]
    },
    implementations: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_module_branches.call(cols: [:id, :repo_id]),
                            lambda__segment_impls.call(cols: [:id, :display_name, :group_id, :repo, :branch])]
    },
    repos: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id]),
                                  lambda__segment_repos.call(cols: [:id, :display_name, :group_id, :repo_name, :local_dir, :remote_repo_name, :remote_repo_namespace])]
    },
    version_info: {
      type: :json,
      hidden: true,
      remote_dependencies: [lambda__segment_module_branches.call(cols: ModuleBranch.common_columns())]
    },
    module_branches_with_repos: {
      type: :json,
      hidden: true,
      remote_dependencies:       [lambda__segment_module_branches.call(cols: [:id, :repo_id, :version, :dsl_parsed]),
                                  lambda__segment_repos.call(cols: [:id, :repo_name, :local_dir])
     ]
    },
  },
  many_to_one: [:project, :library], #MOD_RESTRUCT: may remove library as parent
  one_to_many: [:module_branch]
}