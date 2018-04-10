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
  schema: :module,
  table: :module_ref_sha,
  columns: {
    sha: { type: :varchar, size: 50 },
    repo_name: { type: :varchar, size: 50 },
    branch_name: { type: :varchar, size: 250 },
    module_name: { type: :varchar, size: 250 },
    module_branch_id: {
      type: :bigint,
      foreign_key_rel_type: :module_branch,
      on_delete: :cascade,
      on_update: :cascade
    },
  },
  many_to_one: [:component], #this is an assembly
}
