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
        assembly_instance.get_augmented_port_links(filter: opts[:filter]).map { |port_link| print_form_hash(port_link, context: opts[:context]) } +
          assembly_instance.get_augmented_ports(mark_unconnected: true).select { |port| port[:unconnected] }.map { |r| print_form_hash(r, opts) }
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

     private

      Info = Struct.new(:service_type, :base_ref, :dep_ref, :required, :description) 
      def self.print_form_hash(object, opts = {})
        info = 
          if object.is_a?(PortLink)
            print_form_hash__from_port_link(object)
          elsif object.is_a?(Port)
            print_form_hash__from_port(object)
          else
            fail Error, "Unexpected object type '#{object.class}'"
          end
      
        ret = {
          id: object.id,
          type: info.service_type,
          base_component: info.base_ref
        }
        ret.merge!(dependent_component: info.dep_ref) if info.dep_ref
        ret.merge!(required: info.required) if info.required
        ret.merge!(description: info.description) if info.description
        ret
      end

      def self.print_form_hash__from_port_link(port_link)
        base_ref = dep_ref = description = required = nil
        # TODO: confusing that input/output on port link does not reflect what is logical input/output
        if port_link[:input_port][:direction] == 'input'
          base_ref = port_ref(port_link, :input)
          dep_ref  = port_ref(port_link, :output) 
        else
          base_ref = port_ref(port_link, :output)
          dep_ref  = port_ref(port_link, :input)
        end
        service_type = port_link[:input_port].link_def_name

        Info.new(service_type, base_ref, dep_ref, required, description) 
      end

      def self.print_form_hash__from_port(port)
        dep_ref = required = description = nil

        base_ref     = port.display_name_print_form
        service_type = port.link_def_name

        if link_def = port[:link_def]
          required = port[:required]
          description = port[:description]
        end
        Info.new(service_type, base_ref, dep_ref, required, description) 
      end

      def self.port_ref(port_link, dir)
        aug_port = port_link["#{dir}_port".to_sym].merge(node: port_link["#{dir}_node".to_sym], nested_component: port_link["#{dir}_component".to_sym])
        aug_port.display_name_print_form(hide_assembly_wide_node: true)
      end

    end
  end
end
