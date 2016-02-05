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
    class AssemblyLevel < self
      def type
        :assembly_level
      end

      def attribute_idhs
        @attribute_stacks.map { |attr| attr[:attribute].id_handle() }
      end

      def component_instance
        nil
      end

      def set_parent_and_attributes!(assembly_idh, opts = {})
        attributes = ret_matching_attributes(:component, [assembly_idh], pattern)
        # if does not exist then create the attribute if create option is true
        # if exists and create flag exsists we just assign it new value
        if attributes.empty? && create_this_type?(opts)
          af = ret_filter(pattern, :attribute)
          # attribute must have simple form
          unless af.is_a?(Array) && af.size == 3 && af[0..1] == [:eq, :display_name]
            fail Error.new("cannot create new attribute from attribute pattern #{pattern}")
          end

          attr_properties = opts[:attribute_properties] || {}
          field_def = { 'display_name' => af[2] }

          unless attr_properties.empty?
            if attr_properties[:dynamic]
              fail ErrorUsage.new('Illegal to include the :dynamic option on an assembly level attribute')
            elsif required = attr_properties[:required]
              field_def.merge!('required' => required)
            end
            set_attribute_properties!(attr_properties)
          end

          @created = true
          attribute_idhs = assembly_idh.create_object().create_or_modify_field_def(field_def)

          attributes = attribute_idhs.map do |idh|
            attr = idh.create_object()
            attr.update_object!(:display_name)
            attr
          end
        end

        assembly = assembly_idh.create_object()
        assembly.update_object!(:display_name)

        @attribute_stacks = attributes.map do |attr|
          {
            assembly: assembly,
            attribute: attr
          }
        end

        self
      end
    end
  end; end
end; end