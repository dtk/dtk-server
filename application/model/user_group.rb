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
module XYZ
  class UserGroup < Model
    def self.all_groupname
      'all'
    end

    def self.private_groupname(username)
      "user-#{username}"
    end

    def self.get_all_group(model_handle)
      get_by_groupname(model_handle, all_groupname())
    end

    def self.get_private_group(model_handle, username)
      get_by_groupname(model_handle, private_groupname(username))
    end

    def self.get_by_groupname(model_handle, groupname)
      sp_hash = {
        cols: [:id, :groupname],
        filter: [:eq, :groupname, groupname]
      }
      get_obj(model_handle, sp_hash)
    end
  end
end