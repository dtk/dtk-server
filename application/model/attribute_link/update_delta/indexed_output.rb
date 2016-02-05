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
module DTK; class AttributeLink
  class UpdateDelta
    class IndexedOutput < self
      # Output is an array that gets indexed to generate value for the input
      def self.update_attribute_values(attr_mh, update_deltas, _opts = {})
        ndx_ret = {}
        attr_link_updates = []
        ndx_connected_index_maps = get_ndx_connected_index_maps(attr_mh, update_deltas.map { |r| r[:source_output_id] })

        id_list = update_deltas.map { |r| r[:id] }
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }

          ndx_attr_updates = update_deltas.inject({}) do |h, update_delta|
            attr_id = update_delta[:id]
            existing_val = ndx_existing_vals[attr_id] || []
            connected_index_maps = ndx_connected_index_maps[update_delta[:source_output_id]] || []
            output_index = connected_index_maps.size
            attr_link_update = {
              id: update_delta[:attr_link_id],
              index_map: IndexMap.generate_for_indexed_output(output_index)
            }
            attr_link_updates << attr_link_update

            value_derived = (update_delta[:output_value] || [])[output_index]
            replacement_row = { id: attr_id, value_derived: value_derived }

            ndx_ret.merge!(attr_id => replacement_row.merge(source_output_id: update_delta[:source_output_id], old_value_derived: existing_val))
            h.merge(attr_id => replacement_row)
          end
          # ndx_attr_updates.values is vaule that is used for update in select_process_and_update
          ndx_attr_updates.values
        end

        # update the index_maps on the links
        Model.update_from_rows(attr_mh.createMH(:attribute_link), attr_link_updates)

        ndx_ret.values
      end
     
      private

      # index maps on attributelinks connected to the output attributes
      def self.get_ndx_connected_index_maps(attr_mh, output_attr_ids)
        ret = {}
        sp_hash = {
          cols:   [:id,:group_id, :output_id, :index_map],
          filter: [:oneof, :output_id, output_attr_ids] 
        }
        attr_link_mh = attr_mh.createMH(:attribute_link)
        Model.get_objs(attr_link_mh, sp_hash).each do |r|
          if index_map = r[:index_map]
            (ret[r[:output_id]] ||= []) << index_map
          end 
        end
        ret
      end

    end
  end
end; end