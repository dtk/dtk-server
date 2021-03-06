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
  class Attribute
    module GroupClassMixin
      # marked with "!" because augments info
      def ret_grouped_attributes!(augmented_attr_list, opts = {})
        prune_set = opts[:types_to_keep]
        add_missing_info_for_group_attrs!(augmented_attr_list)
        
        ret = []
        augmented_attr_list.each do |attr|
          type = attr.attribute_value_type()
          ret << attr.merge(attr_val_type: type) if prune_set.nil? || type.type_of?(*prune_set)
        end
        ret
      end
      
      private
      
      # adds port type info and required
      def add_missing_info_for_group_attrs!(augmented_attr_list)
        dependency_analysis(augmented_attr_list) do |attr_in, _link, attr_out|
          attr_in.merge!(port_type: 'input')
          if attr_in[:required] && attr_out and not attr_out[:dynamic]
            attr_out.merge!(required: true)
          end
        end
      end
    end
    
    class AttrValType
      def self.create(type, attr)
        klass = AttrValTypeMap[type.to_sym]
        if klass then klass.new(type, attr)
        else fail Error.new("attribute value type (#{type}) not treated")
        end
      end
      
      # disjunction of types
      def type_of?(*types)
        types.find do |type|
          unless type_klass = AttrValTypeMap[type]
            Log.error("illegal type given #{type}")
          next
          end
          self.is_a?(type_klass)
        end ? true : nil
      end
      
      private
      
      def initialize(type, attr)
        @type = type.to_sym
        @is_set = attr[:attribute_value] ? true : false #TODO: handling legitimate nil values
      end
    end

    # TODO: if dont have type hierarchy then can simplify
    class AttrValTypeRequired < AttrValType
    end
    class AttrValTypeNotRequired < AttrValType
    end
    class AttrValTypeDynamic < AttrValType
    end
    class AttrValTypeLinked < AttrValType
    end
    
    AttrValTypeMap = {
      required: AttrValTypeRequired,
      not_required: AttrValTypeNotRequired,
      dynamic: AttrValTypeDynamic,
      linked: AttrValTypeLinked
    }
    
    module GroupInstanceMixin
      def attribute_value_type
        type =
          # TODO: need to clean up special processing of sap__l4 because marked as output port but also input port (from internal connections)
          if self[:semantic_type_summary] == 'sap__l4' then :linked
          elsif self[:dynamic] then :dynamic
          elsif self[:port_type] == 'input' then :linked
          elsif self[:required] then :required
          else :not_required
          end
        fail Error.new('Cannot detect type of attribute') unless type
        AttrValType.create(type, self)
      end
    end
  end
end
