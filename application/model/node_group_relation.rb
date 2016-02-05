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
  class NodeGroupRelation < Model
    def self.get_node_member_assembly?(node_member_idh)
      sp_hash = {
        cols: [:id, :node_member_assembly],
        filter: [:eq, :node_id, node_member_idh.get_id()]
      }
      ngr = get_obj(node_member_idh.createMH(:node_group_relation), sp_hash)
      ngr && ngr[:assembly]
    end

    def spans_target?
      update_object!(:datacenter_datacenter_id, :node_id)
      if self[:node_id].nil? && self[:datacenter_datacenter_id]
        id_handle(model_name: :target, id: self[:datacenter_datacenter_id])
      end
    end

    def self.spans_target?(ngr_list)
      if ngr_list.size == 1
        ngr_list.first.spans_target?()
      end
    end

    def self.create_to_span_target?(node_group_idh, target_idh, opts = {})
      target_id = target_idh.get_id()
      node_group_id = node_group_idh.get_id

      ngr_mh = node_group_idh.create_peerMH(:node_group_relation)

      # check if not created already
      unless opts[:donot_check_if_exists]
        sp_hash = {
          cols: [:id, :node_id],
          filter: [:and, [:eq, :node_group_id, node_group_id], [:eq, :datacenter_datacenter_id, target_id]]
        }
        matches = get_objs(ngr_mh, sp_hash)
        error = nil
        if matches.size > 1
          error = true
        else matches.size == 1
          if matches.spans_target?()
            return
          else
            error = true
          end
        end
        if error
          fail ErrorUsage.new('Cannot create a node group into spanning target if attached to spsecific nodes')
        end
      end
      display_name = "spans-target-#{target_id}"
      create_row = {
        ref: display_name,
        display_name: display_name,
        datacenter_datacenter_id: target_id,
        node_group_id: node_group_id
      }
      create_from_row(ngr_mh, create_row)
    end
  end
end