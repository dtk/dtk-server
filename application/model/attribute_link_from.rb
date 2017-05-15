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
  class AttributeLinkFrom < Model
    def self.common_columns
      [:id, :group_id, :display_name, :component_red]
    end
    def self.get_for_attribute_id(mh, attribute_id)
      sp_hash = {
        cols: [:id, :ref, :display_name, :component_ref, :attribute_id],
        filter: [:eq, :attribute_id, attribute_id]
      }
      get_objs(mh, sp_hash)
    end
  end
end