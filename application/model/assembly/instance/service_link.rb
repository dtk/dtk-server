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
  class Assembly::Instance
    class ServiceLink
      r8_nested_require('service_link', 'factory')

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end

      def self.delete(port_link_idhs)
        if port_link_idhs.is_a?(Array)
          return if port_link_idhs.empty?
        else
          port_link_idhs = [port_link_idhs]
        end

        aug_attr_links = get_augmented_attribute_links(port_link_idhs)
        attr_mh = port_link_idhs.first.createMH(:attribute)
        Model.Transaction do
          AttributeLink.update_for_delete_links(attr_mh, aug_attr_links)
          port_link_idhs.map { |port_link_idh| Model.delete_instance(port_link_idh) }
        end
      end

      def self.print_form_hash(object, opts = {})
        # set the following (some can have nil as legal value)
        service_type = base_ref = required = description = nil
        id = object[:id]
        if object.is_a?(PortLink)
          port_link = object
          input_port = print_form_hash__port(port_link[:input_port], port_link[:input_node], opts)
          output_port = print_form_hash__port(port_link[:output_port], port_link[:output_node], opts)
          service_type = port_link[:input_port].link_def_name()
          if service_type != port_link[:output_port].link_def_name()
            Log.error('input and output link defs are not equal')
          end
          # TODO: confusing that input/output on port link does not reflect what is logical input/output
          if port_link[:input_port][:direction] == 'input'
            # base_ref = input_port
            base_port = port_link[:input_port].merge!(node: port_link[:input_node], nested_component: port_link[:input_component])
            base_ref  = base_port.display_name_print_form(hide_assembly_wide_node: true)

            # dep_ref = output_port
            dep_port = port_link[:output_port].merge!(node: port_link[:output_node], nested_component: port_link[:output_component])
            dep_ref  = dep_port.display_name_print_form(hide_assembly_wide_node: true)
          else
            # base_ref = output_port
            base_port = port_link[:output_port].merge!(node: port_link[:output_node], nested_component: port_link[:output_component])
            base_ref  = base_port.display_name_print_form(hide_assembly_wide_node: true)

            # dep_ref = input_port
            dep_port = port_link[:input_port].merge!(node: port_link[:input_node], nested_component: port_link[:input_component])
            dep_ref  = dep_port.display_name_print_form(hide_assembly_wide_node: true)
          end
        elsif object.is_a?(Port)
          port = object
          base_ref = port.display_name_print_form()
          service_type = port.link_def_name()
          if link_def = port[:link_def]
            required = port[:required]
            description = port[:description]
          end
        else
          fail Error.new("Unexpected object type (#{object.class})")
        end

        ret = {
          id: id,
          type: service_type,
          base_component: base_ref
        }
        ret.merge!(dependent_component: dep_ref) if dep_ref
        ret.merge!(required: required) if required
        ret.merge!(description: description) if description
        ret
      end

      private

      def self.get_augmented_attribute_links(port_link_idhs)
        ret = []
        return ret if port_link_idhs.empty?
        sp_hash = {
          cols: [:id, :group_id, :port_link_id, :input_id, :output_id, :dangling_link_info],
          filter: [:oneof, :port_link_id, port_link_idhs.map(&:get_id)]
        }
        attribute_link_mh = port_link_idhs.first.createMH(:attribute_link)
        Model.get_objs(attribute_link_mh, sp_hash)
      end

      def self.print_form_hash__port(port, node, opts = {})
        port.merge(node: node).display_name_print_form(opts)
      end
    end
  end
end