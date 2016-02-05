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
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      r8_nested_require('target_ref', 'input')
      r8_nested_require('target_ref', 'clone')

      def is_target_ref?
        true
      end
      # handling case where node.class may be a parent of TargetRef, but represents one
      def self.is_target_ref?(node)
        types.include?(node.get_field?(:type))
      end

      # opts can have
      # {:not_deletable => true}
      def self.types(opts = {})
        if opts[:not_deletable]
          TypesNotDeletable
        else
          Types
        end
     end
      Types = [Type::Node.target_ref, Type::Node.target_ref_staged, Type::Node.physical]
      TypesNotDeletable = [Type::Node.physical]

      def self.assembly_node_print_form(target_ref)
        target_ref.update_object!(:ref, :display_name)
        unless name = target_ref[:display_name] || target_ref[:ref]
          return 'NODE'
        end
        if name =~ Regexp.new("^#{physical_node_prefix()}(.+$)")
          Regexp.last_match(1)
        else
          name
        end
      end

      def self.ret_display_name(type, target_ref_name, opts = {})
        case type
          when :physical
            "#{physical_node_prefix()}#{name}"
          when :base_node_link
            ret = target_ref_name
            if index = opts[:index]
              ret = "#{ret}#{IndexDelim}#{index}"
            end
            if assembly = opts[:assembly]
              assembly_name = assembly.get_field?(:display_name)
              ret = "#{assembly_name}#{AssemblyDelim}#{ret}"
            end
            ret
          else
            fail Error.new("Unexpected type (#{type})")
        end
      end

      def self.node_member_index(target_ref)
        node_group_name, node_member_index = split_node_group_name__node_member_index(target_ref)
        unless node_member_index
          Log.error('Unexpected cannot find an index number')
        end
        node_member_index
      end

      def self.node_group_name(target_ref)
        node_group_name, node_member_index = split_node_group_name__node_member_index(target_ref)
        unless node_group_name
          Log.error('Unexpected cannot find an index number')
        end
        node_group_name
      end

      # returns [node_group_name, node_member_index]
      def self.split_node_group_name__node_member_index(target_ref)
        if Type::Node.physical == target_ref.get_field?(:type)
          return nil
        end
        if display_name = target_ref.get_field?(:display_name)
          if display_name =~ Regexp.new("(^.+)#{IndexDelim}([0-9]+$)")
            node_group_name   = $1
            node_member_index = $2
            [node_group_name, node_member_index]
          end
        end
      end
      private_class_method :split_node_group_name__node_member_index

      AssemblyDelim = '::'
      IndexDelim = ':'
      PhysicalNodePrefix = 'physical--'
      def self.physical_node_prefix
        PhysicalNodePrefix
      end

      # returns hash of form {node_id => NodeWithTargetRefs,..}
      NodeWithTargetRefs = Struct.new(:node, :target_refs)
      def self.get_ndx_linked_target_refs(node_mh, node_ids)
        ret = {}
        return ret if node_ids.empty?
        sp_hash = {
          cols: [:id, :display_name, :type, :linked_target_refs],
          filter: [:oneof, :id, node_ids]
        }
        get_objs(node_mh, sp_hash).each do |n|
          n.delete(:node_group_relation)
          target_ref = n.delete(:target_ref)
          pntr = ret[n[:id]] ||= NodeWithTargetRefs.new(n, [])
          pntr.target_refs << target_ref if target_ref
        end
        ret
      end

      # The class method get_nodes(target) gets the target refs
      # opts keys:
      #  :managed
      #  :mark_free_nodes
      #  :cols
      def self.get_nodes(target, opts = {})
        sp_hash = {
          cols: opts[:cols] || [:id, :display_name, :tags, :ref, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          filter: [:and,
                   [:oneof, :type, [Type::Node.target_ref, Type::Node.physical]],
                   [:eq, :datacenter_datacenter_id, target[:id]],
                   opts[:managed] && [:eq, :managed, true]].compact
        }
        node_mh = target.model_handle(:node)
        ret = get_objs(node_mh, sp_hash, keep_ref_cols: true)
        if opts[:mark_free_nodes]
          ndx_matched_target_refs = ndx_target_refs_to_their_instances(ret.map(&:id_handle))
          unless ndx_matched_target_refs.empty?
            ret.each do |r|
              unless ndx_matched_target_refs[r[:id]]
                r.merge!(free_node: true)
              end
            end
          end
        end
        ret
      end

      def self.get_target_running_nodes(target, opts = {})
        active_nodes = []
        sp_hash = {
          cols: opts[:cols] || [:id, :display_name, :tags, :ref, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          filter: [:and,
                   # [:oneof, :type, [Type::Node.target_ref,Type::Node.physical]],
                   [:eq, :datacenter_datacenter_id, target[:id]],
                   opts[:managed] && [:eq, :managed, true]].compact
        }
        node_mh = target.model_handle(:node)
        ret = get_objs(node_mh, sp_hash, keep_ref_cols: true)

        ret.each do |node|
          op_status = node.get_admin_op_status()
          if !node.is_node_group? && op_status.eql?('running')
            active_nodes << node
          end
        end

        active_nodes
      end

      # The class method get_free_nodes returns  managed nodes without any assembly on them
      def self.get_free_nodes(target)
        ret = get_nodes(target, mark_free_nodes: true, managed: true)
        ret.select { |r| r[:free_node] }
      end

      def self.list(target)
        nodes = get_nodes(target, cols: common_columns() + [:ref])
        cols_except_name = common_columns() - [:display_name]
        nodes.map do |n|
          el = n.hash_subset(*cols_except_name)
          #TODO: unify with the assembly print name
          el.merge(display_name: n[:display_name] || n[:ref])
        end.sort { |a, b| a[:display_name] <=> b[:display_name] }
      end

      def self.create_nodes_from_inventory_data(target, inventory_data)
        Input.create_nodes_from_inventory_data(target, inventory_data)
      end

      # returns hash of form {NodeInstanceId -> [target_refe_idh1,...],,}
      # filter can be of form
      #  {:node_instance_idhs => [idh1,,]}, or
      #  {:node_group_relation_idhs => [idh1,,]}
      def self.ndx_matching_target_ref_idhs(filter)
        ret = {}
        filter_field = sample_idh = nil
        if filter[:node_instance_idhs]
          idhs = filter[:node_instance_idhs]
          filter_field = :node_group_id
        elsif filter[:node_group_relation_idhs]
          idhs = filter[:node_group_relation_idhs]
          filter_field = :id
        else
          fail Error.new("Unexpected filter: #{filter.inspect}")
        end
        if idhs.empty?
          return ret
        end

        #node_group_id matches on instance side and node_id on target ref side
        sp_hash = {
          cols: [:node_id, :node_group_id],
          filter: [:oneof, filter_field, idhs.map(&:get_id)]
        }
        sample_idh = idhs.first
        target_ref_mh = sample_idh.createMH(:node)
        ngr_mh = sample_idh.createMH(:node_group_relation)
        Model.get_objs(ngr_mh, sp_hash).each do |r|
          node_id = r[:node_group_id]
          (ret[node_id] ||= []) << target_ref_mh.createIDH(id: r[:node_id])
        end
        ret
      end

      def self.get_reference_count(target_ref)
        sp_hash = {
          cols: [:id, :group_id],
          filter: [:eq, :node_id, target_ref.id]
        }
        ngr_mh = target_ref.model_handle(:node_group_relation)
        Model.get_objs(ngr_mh, sp_hash).size
      end

      class Info
        attr_reader :target_ref, :ref_count
        def initialize(target_ref)
          @target_ref = target_ref
          @ref_count = 0
        end

        def increase_ref_count
          @ref_count += 1
        end
      end
      # returns array of Info elements; should only be called on non target ref
      def self.get_linked_target_refs_info(node_instance)
        get_ndx_linked_target_refs_info([node_instance]).values.first || []
      end

      private

      def self.get_ndx_linked_target_refs_info(node_instances)
        ret = {}
        if node_instances.empty?
          return ret
        end
        sp_hash = {
          cols: [:node_group_id, :target_refs_with_links],
          filter: [:oneof, :node_group_id, node_instances.map { |n| n[:id] }]
        }
        ndx_ret = {}
        ngr_mh = node_instances.first.model_handle(:node_group_relation)
        get_objs(ngr_mh, sp_hash).each do |r|
          node_id = r[:node_group_id]
          second_ndx = r[:target_ref].id
          info = (ndx_ret[node_id] ||= {})[second_ndx] ||= Info.new(r[:target_ref])
          info.increase_ref_count()
        end
        ndx_ret.inject({}) { |h, (node_id, ndx_info)| h.merge(node_id => ndx_info.values) }
      end

      # returns hash of form {TargetRefId => [matching_node_instance1,,],}
      def self.ndx_target_refs_to_their_instances(node_target_ref_idhs)
        ret = {}
        return ret if node_target_ref_idhs.empty?
        # object model structure that relates instance to target refs is where instance's :canonical_template_node_id field point to target_ref
        sp_hash = {
          cols: [:id, :display_name, :canonical_template_node_id],
          filter: [:oneof, :canonical_template_node_id, node_target_ref_idhs.map(&:get_id)]
        }
Log.error('see why this is using :canonical_template_node_id and not node_group_relation')
        node_mh = node_target_ref_idhs.first.createMH()
        get_objs(node_mh, sp_hash).each do |r|
          (ret[r[:canonical_template_node_id]] ||= []) << r
        end
        ret
      end
    end
  end
end