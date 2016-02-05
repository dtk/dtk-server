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
{
  schema: :repo,
  table: :repo,
  columns: {
    repo_name: { type: :varchar, size: 100 },
    local_dir: { type: :varchar, size: 100 },
    # TODO: ModuleBranch::Location:  will emove fields :remote_repo_name, :remote_repo_namespace
    remote_repo_name: { type: :varchar, size: 100 }, #non-null if this repo is linked to a remote repo
    remote_repo_namespace: { type: :varchar, size: 30 }  #non-null if this repo is linked to a remote repo
  },
  virtual_columns: {
    base_dir: { type: :varchar, local_dependencies: [:local_dir] }
  },
  one_to_many: [:repo_user_acl]
}