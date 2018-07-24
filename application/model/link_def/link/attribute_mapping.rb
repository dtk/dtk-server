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
  class LinkDef::Link
    class AttributeMapping < HashObject
      require_relative('attribute_mapping/node_group_processor')
      require_relative('attribute_mapping/augmented')
      require_relative('attribute_mapping/parse_helper')
      require_relative('attribute_mapping/all_attributes')
      require_relative('attribute_mapping/error_check')

      include AllAttributes::Mixin

      def self.reify(object)
        if object.is_a?(AttributeMapping)
          object
        elsif object.is_a?(Hash)
          new(object)
        else
          fail Error.new("Unexpected object type (#{object.class})")
        end
      end

      # opts can have keys:
      #   :raise_error
      def aug_attr_mappings__clone_if_needed(link_def_context, opts = {})
        @link_def_context = link_def_context

        if all_attributes_ret = all_attributes_aug_attr_mappings__clone_if_needed?(raise_error: opts[:raise_error])
          return all_attributes_ret
        end

        err_msgs = []
        input_attr_obj, input_path = get_context_attr_obj_with_path(err_msgs, :input)
        output_attr_obj, output_path = get_context_attr_obj_with_path(err_msgs, :output)
        return [] if ErrorCheck.check_for_errors?(err_msgs, self.link_def_context, raise_error: opts[:raise_error])

        attr_and_path_info = {
          input_attr_obj: input_attr_obj,
          input_path: input_path,
          output_attr_obj: output_attr_obj,
          output_path: output_path
        }
        NodeGroupProcessor.aug_attr_mappings__clone_if_needed(self, self.link_def_context, attr_and_path_info, opts)
      end

      # returns a hash with args if this is a function that takes args
      #
      #
      def parse_function_with_args?
        ParseHelper::VarEmbeddedInText.isa?(self) # || other ones we add
      end

      def match_attribute_patterns?(dep_attr_pattern, antec_attr_pattern)
        if dep_attr_pattern.match_attribute_mapping_endpoint?(self[:input]) &&
            antec_attr_pattern.match_attribute_mapping_endpoint?(self[:output])
          self
        end
      end

      protected

      attr_reader :link_def_context

      private

      # returns [attribute_object,unravel_path] and updates error if any error
      def get_context_attr_obj_with_path(err_msgs, dir)
        attr = self[dir]
        context_attr_object = find_context_attr_object(attr)
        # TODO: context_attr_object && .. may not be needed because find_context_attr_object(attr) may always be non nil
        unless context_attr_object && context_attr_object.value
          err_msgs << ErrorCheck.attribute_error_message(attr)
        end
        index_map_path = attr[:path]
        # TODO: if treat :create_component_index need to put in here process_unravel_path and process_create_component_index (from link_defs.rb)
        [context_attr_object, index_map_path && AttributeLink::IndexMap::Path.create_from_array(index_map_path)]
      end

      def find_context_attr_object(attr)
        self.link_def_context.find_attribute_object?(attr[:term_index])
      end

    end
  end
end
