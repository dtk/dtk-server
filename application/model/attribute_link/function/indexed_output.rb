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
    class IndexedOutput < Base
      # called when output is any array that needs to be indexed to yield appropriate scalar; input is a scalar
      def internal_hash_form(opts = {})
        if @output_path and !@output_path.empty?
          raise Error.new("Unexpected that @output_path is not empty")
        end

        output_value = output_value(opts)
        if @index_map.nil?
          UpdateDelta::IndexedOutput.new(output_value: output_value, attr_link_id: @attr_link_id)
        else
          index_map_persisted = true
          UpdateDelta::Partial.new(attr_link_id: @attr_link_id, output_value: output_value, index_map: @index_map, index_map_persisted: index_map_persisted)
        end
      end
    end
  end
end; end