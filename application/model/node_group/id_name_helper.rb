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
  class NodeGroup
    module IdNameHelper
      def self.check_valid_id(model_handle, id)
        check_valid_id_helper(model_handle, id, filter(id: id))
      end
      def self.name_to_id(model_handle, name)
        sp_hash =  {
          cols: [:id],
          filter: filter(display_name: name)
        }
        name_to_id_helper(model_handle, name, sp_hash)
      end
      def self.id_to_name(model_handle, id)
        sp_hash =  {
          cols: [:display_name],
          filter: filter(id: id)
        }
        rows = get_objs(model_handle, sp_hash)
        rows && rows.first[:display_name]
      end

      private

      def self.filter(added_condition_hash)
        FilterBase + [[:eq, added_condition_hash.keys.first, added_condition_hash.values.first]]
      end

      NodeType = 'node_group'
      FilterBase =
        [:and,
         [:eq, :type, NodeType],
         [:neq, :datacenter_datacenter_id, nil]
        ]
    end
  end
end