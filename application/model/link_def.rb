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
  class LinkDef < Model
    require_relative('link_def/link')
    require_relative('link_def/context')
    require_relative('link_def/auto_complete')
    require_relative('link_def/parse_serialized_form')
    require_relative('link_def/info')
    extend ParseSerializedFormClassMixin

    def self.common_columns
      [:id, :group_id, :display_name, :description, :local_or_remote, :link_type, :required, :dangling, :has_external_link, :has_internal_link, :component_component_id]
    end

    def self.get_link_defs_matching_antecendent(dep_cmp_template, antec_cmp_template)
      ret = []
      link_defs = get([dep_cmp_template.id_handle]) 
      return ret if link_defs.empty?
      link_def_idhs = link_defs.map(&:id_handle)
      antec_cmp_type = antec_cmp_template.get_field?(:component_type)
      matching_ld_links = get_link_def_links(link_def_idhs, cols: [:link_def_id], filter: [:eq, :remote_component_type, antec_cmp_type])
      matching_ld_ids = matching_ld_links.map { |ld_link| ld_link[:link_def_id] }
      link_defs.select { |ld| matching_ld_ids.include?(ld[:id]) }
    end

    def self.get(component_template_idhs)
      ret = []
      return ret if component_template_idhs.empty?
      sp_hash = {
        cols: common_columns,
        filter: [:oneof, :component_component_id, component_template_idhs.map(&:get_id)]
      }
      link_def_mh = component_template_idhs.first.createMH(:link_def)
      get_objs(link_def_mh, sp_hash)
    end

    def get_link_def_links(opts = {})
      self.class.get_link_def_links([id_handle], opts)
    end
    def self.get_link_def_links(link_def_idhs, opts = {})
      ret = []
      return ret if link_def_idhs.empty?
      filter = [:oneof, :link_def_id, link_def_idhs.map(&:get_id)]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols: opts[:cols] || Link.common_columns,
        filter: filter
      }
      ld_link_mh = link_def_idhs.first.create_childMH(:link_def_link)
      get_objs(ld_link_mh, sp_hash)
    end

    # ports are augmented with link def under :link_def key
    def self.find_possible_connections(unconnected_aug_ports, output_aug_ports)
      ret = []
      output_aug_ports.each(&:set_port_info!)
      set_link_def_links!(unconnected_aug_ports)
      opts = { port_info_is_set: true, link_def_links_are_set: true }
      unconnected_aug_ports.each do |unc_port|
        ret += unc_port[:link_def].find_possible_connection(unc_port, output_aug_ports, opts)
      end
      ret
    end
    # unc_aug_port and output_aug_ports have keys :node
    def find_possible_connection(unc_aug_port, output_aug_ports, opts = {})
      ret = []
      unless opts[:port_info_is_set]
        output_aug_ports.each(&:set_port_info!)
      end
      unless opts[:link_def_links_are_set]
        LinkDef.set_link_def_links!(unc_aug_port)
      end

      unc_aug_port.set_port_info!
      (unc_aug_port[:link_def][:link_def_links] || []).each do |ld_link|
        matches = ld_link.ret_matches(unc_aug_port, output_aug_ports)
        ret += matches
      end
      ret
    end

    def self.set_link_def_links!(aug_ports)
      aug_ports = [aug_ports] unless aug_ports.is_a?(Array)
      ndx_link_defs = aug_ports.inject({}) do |h, r|
        ld = r[:link_def]
        h.merge(ld[:id] => ld)
      end
      ld_link_cols = [:id, :group_id, :display_name, :type, :position, :remote_component_type, :link_def_id]
      ld_links = get_link_def_links(ndx_link_defs.values.map(&:id_handle), cols: ld_link_cols)
      ld_links.each do |r|
        (ndx_link_defs[r[:link_def_id]][:link_def_links] ||= []) << r
      end
      nil
    end
  end
end
