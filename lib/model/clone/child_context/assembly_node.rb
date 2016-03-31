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
module DTK; class Clone
  class ChildContext
    class AssemblyNode < self
      r8_nested_require('assembly_node', 'match_target_refs')
      r8_nested_require('assembly_node', 'node_match')

      # TODO: see if can remove reference so this does not have to be public
      def hash_el_when_match(node, target_ref, extra_fields = {})
        NodeMatch.hash__when_match(self, node, target_ref, extra_fields)
      end

      private

      def include_list
        [:attribute, :attribute_link, :component, :component_ref, :node_interface, :port]
      end

      def initialize(clone_proc, hash)
        super
        assembly_template_idh = model_handle.createIDH(model_name: :component, id: hash[:ancestor_id])
        target = hash[:target_idh].create_object(model_name: :target_instance)
        matches =
          unless target.iaas_properties.supports_create_image?()
            find_target_ref_matches(target, assembly_template_idh)
          else
            # can either be node templates, meaning spinning up node, or
            #  a match to an existing node in which case the existing node target ref is returned
            find_matches_for_nodes(target, assembly_template_idh)
          end
        merge!(matches: matches) if matches
      end

      # for processing node stubs in an assembly
      def ret_new_objs_info(field_set_to_copy, create_override_attrs)
        ret = []
        ancestor_rel_ds = array_dataset(parent_rels, :target)

        # all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id, :display_name, :type, :ref, :canonical_template_node_id] + parent_rels.first.keys
        node_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols(id: :node_template_id)
        node_template_wc = nil
        node_template_ds = Model.get_objects_just_dataset(model_handle, node_template_wc, Model::FieldSet.opt(node_template_fs))

        target_id = parent_rels.first[:datacenter_datacenter_id]
        sp_hash = {
          cols: [:id, :display_name, :type, :iaas_type],
          filter: [:eq, :id, target_id]
        }
        target = Model.get_obj(model_handle.createMH(:target), sp_hash)

        # mapping from node stub to node template and overriding appropriate node template columns
        unless matches.empty?
          ndx_node_matches = NodeMatch.ndx_node_matches(matches)
          mappings = ndx_node_matches.values.map{ |m| m.mapping}
          mapping_ds = array_dataset(mappings, :mapping)

          select_ds = ancestor_rel_ds.join_table(:inner, node_template_ds).join_table(:inner, mapping_ds, [:node_template_id])
          ret = Model.create_from_select(model_handle, field_set_to_copy, select_ds, create_override_attrs, create_opts)

          # update any external refs if any are set in ndx_node_matches
          update_external_refs!(ret, ndx_node_matches)
          ret.each do |r|
            if node_match = ndx_node_matches[r[:display_name]]
              r[:node_template_id] = node_match.mapping[:node_template_id]
              r.merge!(Aux.hash_subset(node_match.node, [:donot_clone, :target_refs_to_link, :target_refs_exist]))
            end
          end
        end
        ret
      end

      def update_external_refs!(ret, ndx_node_matches)
        ndx_id = ret.inject({}) { |h, r| h.merge(r[:display_name] => r[:id]) }
        external_ref_rows = []
        ndx_node_matches.each_pair do |ndx, node_match|
          if external_ref = node_match.external_ref
            external_ref_rows << { id: ndx_id[ndx], external_ref: external_ref }
          end
        end
        unless external_ref_rows.empty?
          Model.update_from_rows(model_handle, external_ref_rows, partial_value: true)
        end
      end

      def find_target_ref_matches(target, assembly_template_idh)
        sp_hash = {
          cols: [:id, :display_name, :group_id],
          filter: [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        stub_nodes = Model.get_objs(assembly_template_idh.createMH(:node), sp_hash)
        mtr = MatchTargetRefs.new(self)
        case matching_strategy = mtr.matching_strategy(target, stub_nodes)
         when :free_nodes
          mtr.find_free_nodes(target, stub_nodes, assembly_template_idh)
         when :match_tags
           mtr.match_tags(target, stub_nodes, assembly_template_idh)
         else
          fail Error.new("Unexpected matching strategy (#{matching_strategy})")
        end
      end

      def find_matches_for_nodes(target, assembly_template_idh)
        # find the assembly's stub nodes and then use the node binding to find the node templates
        # see what nodes mapping to existing ones and thus shoudl be omitted in clone
        sp_hash = {
          cols: [:id, :display_name, :type, :node_binding_ruleset],
          filter: [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        node_info = Model.get_objs(assembly_template_idh.createMH(:node), sp_hash)

        node_bindings = NodeBindings.get_node_bindings(assembly_template_idh)
        node_mh = target.model_handle(:node)
        target_service = Service::Target.create_from_target(target)

        node_info.map do |node|
          nb_ruleset = node[:node_binding_ruleset]
          node_target = node_bindings && node_bindings.has_node_target?(node.get_field?(:display_name))
          case match_or_create_node?(target, node, node_target, nb_ruleset)
            when :create
              node_template = node_target ?
                target_service.find_node_template_from_node_target(node_target) :
                target_service.find_node_template_from_node_binding_ruleset(nb_ruleset)
              NodeMatch.hash__when_creating_node(self, node, node_template, node_target: node_target)
            when :match
              if target_ref = NodeBindings.create_linked_target_ref?(target, node, node_target)
                NodeMatch.hash__when_match(self, node, target_ref)
              else
                Log.error('Temp logic as default if cannot find_matching_target_ref then create')
                node_template = Node::Template.find_matching_node_template(target, node_binding_ruleset: nb_ruleset)
                NodeMatch.hash__when_creating_node(self, node, node_template)
              end
            else
             fail Error.new('Unexpected return value from match_or_create_node')
          end
        end
      end

      def match_or_create_node?(target, _node, node_target, nb_ruleset)
        if nb_ruleset
          :create
        elsif node_target
          node_target.match_or_create_node?(target)
        else
          :create
        end
      end

      def cleanup_after_error
        Model.delete_instance(model_handle.createIDH(model_name: :component, id: override_attrs[:assembly_id]))
      end
    end
  end
end; end
