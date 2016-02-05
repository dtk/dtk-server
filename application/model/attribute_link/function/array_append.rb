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
  class Function
    class ArrayAppend < Base
      # called when input is an array and each link into it appends the value in
      def internal_hash_form(opts = {})
        output_value = output_value(opts)
        if @index_map.nil? && (@input_path.nil? || @input_path.empty?)
          new_rows = output_value.nil? ? [nil] : (output_semantic_type().is_array? ? output_value : [output_value])
          output_is_array = @output_attr[:semantic_type_object].is_array?()
          UpdateDelta::ArrayAppend.new(array_slice: new_rows, attr_link_id: @attr_link_id, output_is_array: output_is_array)
        else
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || IndexMap.generate_from_paths(@input_path, nil)
          UpdateDelta::Partial.new(attr_link_id: @attr_link_id, output_value: output_value, index_map: index_map, index_map_persisted: index_map_persisted)
        end
      end

    end
  end
end; end