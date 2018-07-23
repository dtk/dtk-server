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
      
      ALL_ATTRIBUTES_REF_INTERNAL_FORM = '__ALL_ATTRIBUTES__'

      require_relative('attribute_mapping/node_group_processor')
      require_relative('attribute_mapping/augmented')
      require_relative('attribute_mapping/parse_helper')

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
        ret = []
        err_msgs = []
        input_attr_obj, input_path = get_context_attr_obj_with_path(err_msgs, :input, link_def_context)
        output_attr_obj, output_path = get_context_attr_obj_with_path(err_msgs, :output, link_def_context)
 
        unless err_msgs.empty?
          aggregated_err_msg = aggregated_error_message(err_msgs, link_def_context)
          if opts[:raise_error]
            fail LinkDef::AutoComplete::FatalError.new(aggregated_err_msg)
          else
            Log.error(aggregated_err_msg)
            return ret
          end
        end

        attr_and_path_info = {
          input_attr_obj: input_attr_obj,
          input_path: input_path,
          output_attr_obj: output_attr_obj,
          output_path: output_path
        }
        NodeGroupProcessor.aug_attr_mappings__clone_if_needed(self, link_def_context, attr_and_path_info, opts)
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

      private

      def aggregated_error_message(err_msgs, link_def_context)
        local_component = link_def_context.local_component_template.display_name_print_form
        remote_component = link_def_context.remote_component_template.display_name_print_form

        error_or_errors = (err_msgs.size == 1 ? 'There is an error' : 'There  are errors')
        ret_err_msg = "#{error_or_errors} on componenent '#{local_component} link def to '#{remote_component}':\n"
        err_msgs.inject(ret_err_msg) { |s, err_msg| s + "  #{err_msg}\n"  }
      end

      # returns [attribute_object,unravel_path] and updates error if any error
      def get_context_attr_obj_with_path(err_msgs, dir, context)
        attr_object = context.find_attribute_object?(self[dir][:term_index])
        unless attr_object && attr_object.value
          err_msgs << attribute_error_message(dir)
        end
        index_map_path = self[dir][:path]
        # TODO: if treat :create_component_index need to put in here process_unravel_path and process_create_component_index (from link_defs.rb)
        [attr_object, index_map_path && AttributeLink::IndexMap::Path.create_from_array(index_map_path)]
      end

      def attribute_error_message(direction)
        err_msg = 
          if attr = self[direction]
            if attr_name = attr[:attribute_name]
              component_ref = attribute_error_message_component_ref(attr)
              "Attribute '#{attr_name}' referenced in attribute mapping is not defined on '#{component_ref}'"
            end
          end

        err_msg || attribute_error_message_unknown
      end

      def attribute_error_message_component_ref(attr)
        if cmp_type = attr[:component_type]
          # meaning that it is a component attribute ref
          Component.component_type_print_form(cmp_type)
        elsif attr[:node_name]
          'node'
        end
      end

     def attribute_error_message_unknown
       Log.error("unexpected that have no pp form for: #{inspect}")
       'Attribute matching link def term does not exist'
     end

    end
  end
end
