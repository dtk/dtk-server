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
    module ServiceLinkMixin
      def add_service_link?(input_cmp_idh, output_cmp_idh, opts = {})
        dependency_name = find_dep_name_raise_error_if_ambiguous(input_cmp_idh, output_cmp_idh, opts)
        ServiceLink::Factory.new(self, input_cmp_idh, output_cmp_idh, dependency_name).add?()
      end

      def list_service_links(opts = {})
        get_opts = Aux.hash_subset(opts, [:filter])
        pp_opts = Aux.hash_subset(opts, [:context, :hide_assembly_wide_node])
        get_augmented_port_links(get_opts).map { |r| ServiceLink.print_form_hash(r, pp_opts) } +
          get_augmented_ports(mark_unconnected: true).select { |r| r[:unconnected] }.map { |r| ServiceLink.print_form_hash(r, pp_opts) }
      end

      def list_connections__possible
        ret = []
        output_ports = []
        unc_ports = []
        get_augmented_ports(mark_unconnected: true).each do |r|
          if r[:direction] == 'output'
            output_ports << r
          elsif r[:unconnected]
            unc_ports << r
          end
        end
        return ret if output_ports.nil? || unc_ports.nil?
        poss_conns = LinkDef.find_possible_connections(unc_ports, output_ports)
        poss_conns.map do |r|
          poss_conn = "#{r[:output_port][:id]}:#{r[:output_port].display_name_print_form()}"
          ServiceLink.print_form_hash(r[:input_port]).merge(possible_connection: poss_conn)
        end.sort { |a, b| a[:service_ref] <=> b[:service_ref] }
      end

      private

      def find_dep_name_raise_error_if_ambiguous(input_cmp_idh, output_cmp_idh, opts = {})
        input_cmp = input_cmp_idh.create_object()
        output_cmp = output_cmp_idh.create_object()
        matching_link_defs = LinkDef.get_link_defs_matching_antecendent(input_cmp, output_cmp)
        matching_link_types = matching_link_defs.map { |ld| ld.get_field?(:link_type) }.uniq

        input_cmp_name = input_cmp.component_type_print_form()
        output_cmp_name = output_cmp.component_type_print_form()

        if dep_name = opts[:dependency_name]
          if matching_link_types.include?(dep_name)
            dep_name
          else
            fail ErrorUsage.new("Specified dependency name (#{dep_name}) does not match any of the dependencies defined between component type (#{input_cmp_name}) and component type (#{output_cmp_name}): #{matching_link_types.join(',')}")
          end
        elsif matching_link_types.size == 1
          matching_link_types.first
        elsif matching_link_types.empty?
          fail ErrorUsage.new("There are no dependencies defined between component type (#{input_cmp_name}) and component type (#{output_cmp_name})")
        else #matching_link_types.size > 1
          fail ErrorUsage.new("Ambiguous which dependency between component type (#{input_cmp_name}) and component type (#{output_cmp_name}) selected; select one of #{matching_link_types.join(',')})")
        end
      end
    end
  end
end