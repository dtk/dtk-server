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
  class AttributeLink
    class AdHoc < Hash
      # Logic is if update meta then meta updated as well as ad_hoc updates for existing component instances
      def self.create_adhoc_links(assembly, target_attr_term, source_attr_term, opts = {})
        parsed_info = Attribute::Pattern::Assembly::Link.parsed_adhoc_link_info(self, assembly, target_attr_term, source_attr_term)
        unless opts[:update_meta] && parsed_info.meta_update_supported?()
          return create_ad_hoc_attribute_links?(assembly, parsed_info.links)
        end

        dep_cmp = parsed_info.dep_component_instance
        peer_cmps = assembly.get_peer_component_instances(dep_cmp)
        # get_peer_component_instances must be done before AssemblyModule::Component::AdHocLink, which modifies parents
        result = AssemblyModule::Component::AdHocLink.update(assembly, parsed_info)
        if link_def_info = result[:link_def_created]
          link_def_hash = link_def_info[:hash_form]
          antec_cmp = parsed_info.antec_component_instance
          create_link_defs_and_component_links(assembly, parsed_info.links, dep_cmp, peer_cmps, antec_cmp, link_def_hash)
        else
          create_attribute_links?(assembly, parsed_info.links, dep_cmp, peer_cmps)
        end
      end

      # params should have
      #  :input_attribute
      #  :output_attribute
      def self.create_simple(assembly, params)
        input_attribute  = params[:input_attribute]
        output_attribute = params[:output_attribute]

        link = { input_id: input_attribute.id, output_id: output_attribute.id }
        opts_create = {
          donot_update_port_info: true,
          donot_create_pending_changes: true,
          attr_rows: [input_attribute, output_attribute]
        }
        AttributeLink.create_attribute_links(assembly.id_handle, [link], opts_create)
      end

      # type should be :source or :target
      def attribute_pattern(type)
        @attr_pattern[type]
      end

      def all_dep_component_instance_hashes(assembly, dep_component, peer_cmps)
        ret = [self]
        # get peer component instances
        return ret if peer_cmps.empty?

        # find whether target or source side matches with dep_component
        dep_side, antec_side, dep_attr_field, antec_attr_field =
          if attribute_pattern(:target).component_instance.id() == dep_component.id()
            [:target, :source, :input_id, :output_id]
          else
            [:source, :target, :output_id, :input_id]
          end

        # find the matching attributes on the peer components
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, [:oneof, :component_component_id, peer_cmps.map(&:id)],
                   [:eq, :display_name, attribute_pattern(dep_side).attribute_name]]
        }
        assembly_id = assembly.id()
        antec_attr_id = attribute_pattern(antec_side).attribute_id()
        peer_attrs = Model.get_objs(assembly.model_handle(:attribute), sp_hash).map do |dep_attr|
          {
            dep_attr_field => dep_attr.id(),
            antec_attr_field => antec_attr_id,
            :assembly_id => assembly_id
          }
        end

        ret + peer_attrs
      end

      private

      def initialize(hash, target_attr_pattern, source_attr_pattern)
        super()
        replace(hash)
        @attr_pattern = {
          target: target_attr_pattern,
          source: source_attr_pattern.attribute_pattern
        }
      end

      def self.create_link_defs_and_component_links(assembly, _parsed_adhoc_links, dep_cmp, peer_cmps, antec_cmp, link_def_hash)
        # This method iterates over all the components in assembly that includes dep_cmp and its peers and for each
        # adds the link_def to it and then service link between this and antec_cmp
        link_name = link_def_hash.values.first[:link_type]
        ([dep_cmp] + peer_cmps).each do |cmp|
          # TODO: can be more efficient to combine these two operations and see if can bulk them
          Model.input_hash_content_into_model(cmp.id_handle, link_def: link_def_hash)
          assembly.add_component_link(cmp, antec_cmp, link_name: link_name)
        end
      end

      def self.create_attribute_links?(assembly, parsed_adhoc_links, dep_component, peer_components)
        attr_link_rows = parsed_adhoc_links.inject([]) do |a, adhoc_link|
          a + adhoc_link.all_dep_component_instance_hashes(assembly, dep_component, peer_components)
        end
        create_ad_hoc_attribute_links?(assembly, attr_link_rows)
      end

      def self.create_ad_hoc_attribute_links?(assembly, attr_link_rows)
        ret = []
        existing_links = get_matching_ad_hoc_attribute_links(assembly, attr_link_rows)
        new_links = attr_link_rows.reject do |link|
          existing_links.find do |existing_link|
            existing_link[:output_id] == link[:output_id] &&
              existing_link[:input_id] == link[:input_id]
          end
        end
        return ret if new_links.empty?
        opts_create = {
          donot_update_port_info: true,
          donot_create_pending_changes: true
        }
        AttributeLink.create_attribute_links(assembly.id_handle(), new_links, opts_create)
      end

      def self.get_matching_ad_hoc_attribute_links(assembly, attr_link_rows)
        ret = []
        return ret if attr_link_rows.empty?
        assembly_id = assembly.id()
        disjunct_array = attr_link_rows.map do |r|
          [:and, [:eq, :assembly_id, assembly_id],
           [:eq, :output_id, r[:output_id]],
           [:eq, :input_id, r[:input_id]]]
        end
        sp_hash = {
          cols: [:id, :group_id, :assembly_id, :input_id, :output_id],
          filter: [:or] + disjunct_array
        }
        Model.get_objs(assembly.model_handle(:attribute_link), sp_hash)
      end
    end
  end
end
