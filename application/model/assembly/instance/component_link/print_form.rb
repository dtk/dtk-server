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
  class Assembly::Instance::ComponentLink
    module PrintForm
      # opts can have keys:
      #   :context
      #   :filter
      def self.list_component_links(assembly_instance, opts = {})
        pp_opts = { context: opts[:context] }
        get_augmented_port_links(filter: opts[:filter]).map { |r| print_form_hash(r, pp_opts) } +
          assembly_instance.get_augmented_ports(mark_unconnected: true).select { |r| r[:unconnected] }.map { |r| print_form_hash(r, pp_opts) }
      end

      def self.list_possible_component_links(assembly_instance)
        ret = []
        output_ports = []
        unc_ports = []
        assembly_instance.get_augmented_ports(mark_unconnected: true).each do |r|
          if r[:direction] == 'output'
            output_ports << r
          elsif r[:unconnected]
            unc_ports << r
          end
        end
        return ret if output_ports.nil? || unc_ports.nil?
        poss_conns = LinkDef.find_possible_connections(unc_ports, output_ports)
        poss_conns.map do |r|
          poss_conn = "#{r[:output_port][:id]}:#{r[:output_port].display_name_print_form}"
          print_form_hash(r[:input_port]).merge(possible_connection: poss_conn)
        end.sort { |a, b| a[:service_ref] <=> b[:service_ref] }
      end

      # opts can have keys
      #   :context
      # object is of type PortLink or Port
      # TODO: can this any longer be passed a Port object
      def self.print_form_hash(object, opts = {})
        opts = { hide_assembly_wide_node: true }.merge(opts)
        # set the following (some can have nil as legal value)
        service_type = base_ref = required = description = nil
        id = object[:id]
        if object.is_a?(PortLink)
          port_link = object
          input_port = print_form_hash__port(port_link[:input_port], port_link[:input_node], opts)
          output_port = print_form_hash__port(port_link[:output_port], port_link[:output_node], opts)
          service_type = port_link[:input_port].link_def_name
          if service_type != port_link[:output_port].link_def_name
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
          base_ref = port.display_name_print_form
          service_type = port.link_def_name
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

      def self.print_form_hash__port(port, node, opts = {})
        port.merge(node: node).display_name_print_form(opts)
      end

    end
  end
end
