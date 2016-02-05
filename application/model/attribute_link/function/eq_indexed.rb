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
    class EqIndexed < Base
      # called when it is an equlaity setting between indexed values on input and output side.
      # Can be the null index on one of the sides meaning to take whole value
      # TODO: can simplify because only will be called when input is not an array
      def internal_hash_form(opts = {})
        output_value = output_value(opts)
        if @index_map.nil? && (@input_path.nil? || @input_path.empty?) && (@output_path.nil? || @output_path.empty?)
          new_rows = output_value.nil? ? [nil] : (output_semantic_type().is_array? ? output_value : [output_value])
          hash = {
            array_slice:  new_rows,
            attr_link_id: @attr_link_id
          }
          UpdateDelta::ArrayAppend.new(hash)
        else
          hash = {
            attr_link_id:        @attr_link_id,
            output_value:        output_value,
            index_map:           @index_map || IndexMap.generate_from_paths(@input_path, @output_path),
            index_map_persisted: @index_map ? true : false
          }
          UpdateDelta::Partial.new(hash)
        end
      end
    end
  end
end; end