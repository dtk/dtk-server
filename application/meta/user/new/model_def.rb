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
  schema: :app_user, #cannot use schema user because reserved
  table: :user,
  columns: {
    username: { type: :varchar, size: 50 },
    password: { type: :varchar, size: 100 },
    catalog_username: { type: :varchar, size: 50 },
    catalog_password: { type: :varchar, size: 400 },
    first_name: { type: :varchar, size: 50 },
    last_name: { type: :varchar, size: 50 },
    is_admin_user: { type: :boolean },
    email_addresses_primary: { type: :varchar, size: 50 },
    settings: { type: :json },
    status: { type: :varchar, size: 50 },
    ssh_rsa_pub_keys: { type: :json },
    default_namespace: { type: :varchar, size: 50 }
  },
  virtual_columns: {
    user_groups: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :user_group_relation,
         join_type: :left_outer,
         join_cond: { user_id: :user__id },
         cols: [:user_group_id]
       },
                                  {
                                    model_name: :user_group,
                                    convert: true,
                                    join_type: :left_outer,
                                    join_cond: { id: :user_group_relation__user_group_id },
                                    cols: [:id, :groupname]
                                  }]
    }
  },
  one_to_many: [:access_rule]
}