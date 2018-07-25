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
  class LinkDef::Link::AttributeMapping
    class AllAttributes
      INTERNAL_NAME = '__ALL_ATTRIBUTES__'
      # opts can have keys:
      #  :raise_error
      def initialize(attribute_mapping, input_attr_obj, input_path, output_attr_obj, opts = {})
        @attribute_mapping = attribute_mapping
        @input_attr_obj    = input_attr_obj
        @input_path        = input_path 
        @output_attr_obj   = output_attr_obj
      end
      
      # opts can have keys:
      #  :raise_error
      def process(opts = {})
        base_output_path = nil
        self.output_attr_obj.expanded_all_attribute_array.inject([]) do |a, base_output_attr_obj|
          # base_input_path is set so that attribute named foo is stuffed under foo key
          # self.input_path i sincluded in case it has offset
          base_input_path  = (self.input_path || []) + [base_output_attr_obj.attribute_ref]
          a + self.attribute_mapping.aug_attr_mappings_helper(input_attr_obj, base_input_path, base_output_attr_obj, base_output_path, opts)
        end
      end

      module Mixin
        # opts can have keys:
        #  :raise_error
        def all_attributes_aug_attr_mappings__clone_if_needed?(opts = {})
          err_msgs = []
          input_attr_obj, input_path = get_context_attr_obj_with_path(err_msgs, :input)
          return [] if ErrorCheck.check_for_errors?(err_msgs, self.link_def_context, raise_error: opts[:raise_error])
          if output_attr_obj =  output_is_all_attributes_ref?
            AllAttributes.new(self, input_attr_obj, input_path, output_attr_obj).process(opts)
          end
        end

        private
        # if output_is_all_attributes_ref this returns output+attr_object
        def output_is_all_attributes_ref?
          attr = self[:output]
          context_attr_object = find_context_attr_object(attr)
          # TODO: context_attr_object && .. may not be needed because find_context_attr_object(attr) may always be non nil
          if context_attr_object and !context_attr_object.value and context_attr_object.attribute_ref == INTERNAL_NAME
            context_attr_object
          end
        end
      end

      protected

      attr_reader :attribute_mapping, :input_attr_obj, :input_path, :output_attr_obj

    end
  end
end
