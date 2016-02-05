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
      def initialize(pattern, parent_obj)
        super(pattern)
        @id = pattern.to_i
        if parent_obj.is_a?(::DTK::Node)
          raise_error_if_not_node_attr_id(@id, parent_obj)
        elsif parent_obj.is_a?(::DTK::Assembly)
          raise_error_if_not_assembly_attr_id(@id, parent_obj)
        else
          fail Error.new("Unexpected parent object type (#{parent_obj.class})")
        end
      end

      def type
        :explicit_id
      end

      attr_reader :attribute_idhs

      def set_parent_and_attributes!(parent_idh, _opts = {})
        @attribute_idhs = [parent_idh.createIDH(model_name: :attribute, id: id())]
        self
      end

      def valid_value?(_value, _attribute_idh = nil)
        # TODO: not testing yet valid_value? for explicit_id type
        # vacuously true
        true
      end

      private

      def raise_error_if_not_node_attr_id(attr_id, node)
        unless node.get_node_and_component_attributes().find { |r| r[:id] == attr_id }
          fail ErrorUsage.new("Illegal attribute id (#{attr_id}) for node")
        end
      end

      def raise_error_if_not_assembly_attr_id(attr_id, assembly)
        unless assembly.get_attributes_all_levels().find { |r| r[:id] == attr_id }
          fail ErrorUsage.new("Illegal attribute id (#{attr_id}) for assembly")
        end
      end
    end
  end; end
end; end