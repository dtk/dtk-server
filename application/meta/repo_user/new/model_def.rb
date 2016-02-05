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
  table: :user,
  columns: {
    username: { type: :varchar, size: 50 },
    index: { type: :integer, default: 1 }, #TODO: to prevent obscure race condition may make this a sequence
    type: { type: :varchar, size: 20 }, #system | node | client
    component_module_direct_access: { type: :boolean, default: false },
    service_module_direct_access: { type: :boolean, default: false },
    repo_manager_direct_access: { type: :boolean, default: false },
    ssh_rsa_pub_key: { type: :text },
    ssh_rsa_private_key: { type: :text } #used when handing out keys to node types; #TODO: may encrypt in db
  }
}