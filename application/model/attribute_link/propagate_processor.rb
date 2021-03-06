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
  # TODO: may fold into AttributeLink::Function              
  #       this is bridge to legacy way of handlding updating values
  class PropagateProcessor
    r8_nested_require('propagate_processor', 'legacy')
    include Propagate::Mixin
    include LegacyMixin

    def self.compute_update_deltas(attr_link, input_attr, output_attr)
      new(attr_link, input_attr, output_attr).compute_update_deltas
    end

    attr_reader :function, :index_map, :attr_link_id, :input_attr, :output_attr, :input_path, :output_path
    def initialize(attr_link, input_attr, output_attr)
      @function = attr_link[:function]
      @index_map = IndexMap.convert_if_needed(attr_link[:index_map])
      @attr_link_id =  attr_link[:id]
      @input_attr = input_attr
      @output_attr = output_attr
      @input_path = attr_link[:input_path]
      @output_path = attr_link[:output_path]
    end

    def compute_update_deltas 
      hash_ret = Function.internal_hash_form?(@function, self)

      unless hash_ret ||= legacy_internal_hash_form?()
        fail Error::NotImplemented.new("propagate value not implemented yet for fn #{@function}")
      end

      (hash_ret.is_a?(UpdateDelta) ? hash_ret : UpdateDelta.new(hash_ret)).merge(id: @input_attr[:id], source_output_id: @output_attr[:id])
    end

  end
end; end