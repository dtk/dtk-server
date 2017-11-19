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
    class PrintForm
      require_relative('print_form/element')

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end
      private :initialize
      
      # opts can have keys:
      #   :context
      #   :filter
      def self.list_component_links(assembly_instance, opts = {})
        new(assembly_instance).list_component_links(opts)
      end
      def list_component_links(opts = {})
        component_links = augmented_port_links(filter: opts[:filter]).map { |port_link| Element.print_form_hash(port_link, context: opts[:context]) } +
          augmented_ports(mark_unconnected: true).select { |port| port[:unconnected] }.map { |r| Element.print_form_hash(r, opts) }
        fixup!(component_links)
      end
      
      def self.list_possible_component_links(assembly_instance)
        new(assembly_instance).list_possible_component_links
      end
      def list_possible_component_links
        ret = []
        output_ports = []
        unc_ports = []
        augmented_ports(mark_unconnected: true).each do |r|
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
          Element.print_form_hash(r[:input_port]).merge(possible_connection: poss_conn)
        end.sort { |a, b| a[:service_ref] <=> b[:service_ref] }
      end
      
      
      protected
      
      attr_reader :assembly_instance
      
      def component_info 
        @component_info  ||= ret_component_info
      end
      
      private
      
      # opts can have keys
      #   :filter
      def augmented_port_links(opts = {})
        self.assembly_instance.get_augmented_port_links(filter: opts[:filter])
      end

      # opts can have keys
      #   :mark_unconnected
      def augmented_ports(opts = {})
        self.assembly_instance.get_augmented_ports(mark_unconnected: opts[:mark_unconnected])
      end

      # TODO: move from cleanup hack to inside elements.rb
      def fixup!(component_links)
        self.component_info.each do |cmp|
          cmp_ids = cmp[:id] unless cmp[:id].nil?
          cmp_id = ''
          if cmp_ids.is_a?(Array) && cmp_ids.size == 1
            cmp_ids.each do |id|
              cmp_id = id
            end
          elsif cmp_ids.is_a?(Fixnum)
            cmp_id = cmp_ids
          end
          component_links.each do |link|
            if link[:type] == cmp[:depends_on] 
              if cmp_ids.size > 1 
                split = cmp[:satisfied_by].split(',')
                if split.size > 1
                  split.each_with_index do |stat, index|
                    if link[:linked_cmp_id] == cmp[:id][index]
                      link.merge!(satisfied_by: stat.strip)
                    end
                  end
                end
              end
              if cmp_id == link[:linked_cmp_id]
                link.merge!(satisfied_by: cmp[:satisfied_by])
              end
            end
          end
        end
        component_links
      end

      def ret_component_info
        opts =  {
          detail_level: nil,
          detail_to_include: [:component_dependencies],
          remote_links: true
        }
        self.assembly_instance.info_about(:components, Opts.new(opts))
      end
      
    end
  end
end

