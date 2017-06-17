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
module DTK; class Attribute
  class Pattern; class Type
    class ExplicitId < self
      def initialize(pattern, assembly)
        super(pattern)
        @id        = pattern.to_i
        @attribute = get_attribute?(@id, assembly)
        fail ErrorUsage, "Illegal attribute id '#{@id}'" unless @attribute
      end

      def type
        :explicit_id
      end

      def semantic_data_type(_attribute_idh = nil)
        @attribute.get_field?(:semantic_data_type)
      end

      attr_reader :attribute_idhs, :id

      def set_parent_and_attributes!(parent_idh, _opts = {})
        @attribute_idhs = [parent_idh.createIDH(model_name: :attribute, id: id())]
        self
      end

      private

      def get_attribute?(attr_id, assembly)
        assembly.get_attributes_all_levels().find { |r| r[:id] == attr_id }
      end

    end
  end; end
end; end
