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
    module ErrorCheck
      # if error, either fails or returns true
      # opts can have keys:
      #   :raise_error
      def self.check_for_errors?(err_msgs, link_def_context, opts = {})
        unless err_msgs.empty?
          aggregated_err_msg = aggregated_error_message(err_msgs, link_def_context)
          if opts[:raise_error]
            fail LinkDef::AutoComplete::FatalError.new(aggregated_err_msg)
          else
            Log.error(aggregated_err_msg)
            true
          end
        end
      end
      
      def self.attribute_error_message(attr)
        err_msg = 
          if attr_name = attr[:attribute_name]
            component_ref = attribute_error_message_component_ref(attr)
            "Attribute '#{attr_name}' referenced in attribute mapping is not defined on '#{component_ref}'"
          end
        err_msg || attribute_error_message_unknown
      end
      
      private
      
      def self.aggregated_error_message(err_msgs, link_def_context)
        local_component = link_def_context.local_component_template.display_name_print_form
        remote_component = link_def_context.remote_component_template.display_name_print_form
        
        error_or_errors = (err_msgs.size == 1 ? 'There is an error' : 'There  are errors')
        ret_err_msg = "#{error_or_errors} on componenent '#{local_component} link def to '#{remote_component}':\n"
        err_msgs.inject(ret_err_msg) { |s, err_msg| s + "  #{err_msg}\n"  }
      end
      
      def self.attribute_error_message_component_ref(attr)
        if cmp_type = attr[:component_type]
          # meaning that it is a component attribute ref
          Component.component_type_print_form(cmp_type)
        elsif attr[:node_name]
          'node'
        end
      end
      
      def self.attribute_error_message_unknown
        Log.error("unexpected that have no pp form for: #{inspect}")
        'Attribute matching link def term does not exist'
      end
      
    end
  end
end
