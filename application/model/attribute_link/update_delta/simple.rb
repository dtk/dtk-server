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
    class Simple
      def self.update_attribute_values(attr_mh, update_deltas, _opts = {})
        ret = []
        id_list = update_deltas.map { |r| r[:id] }
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }
          update_deltas.map do |update_delta|
            attr_id = update_delta[:id]
            existing_val = ndx_existing_vals[attr_id]
            replacement_row = { id: attr_id, value_derived: update_delta[:value_derived] }
            ret << replacement_row.merge(source_output_id: update_delta[:source_output_id], old_value_derived: existing_val)
            replacement_row
          end
        end
        ret
      end
    end
  end
end; end