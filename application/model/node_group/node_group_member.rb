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
  class NodeGroup
    class NodeGroupMember < ::DTK::Node
      def self.model_name
        :node
      end
      def bump_down_associated_node_group_cardinality
        node_group().bump_down_cardinality()
      end

      def clone_post_copy_hook(_clone_copy_output, _opts = {})
        # no op
      end

      # returns NodeGroupMember object if node group member; otherwise retuns nil
      def self.node_group_member?(node)
        if node.kind_of?(NodeGroupMember)
          node
        elsif node.is_target_ref?
          # check if is linked to a node_group to distingusih it from otehr target_refs
          node_group_member_obj = create_stub(node.model_handle(:node_group_member),node)
          if node_group_member_obj.node_group_parent?
            node_group_member_obj
          end
        end
      end

      def index
        (self[:index] || fail(Error, "Unexpeced that self[:index] is nil")).to_i
      end
      # This should only be called if node is a node_group_member although its class may not be NodeGroupMember
      def self.node_group_member_index(node)
        # using node[:index] is  shortcut
        (node[:index] || TargetRef.node_member_index(node)).to_i
      end

      def self.node_group_name(node)
        TargetRef.node_group_name(node)
      end

      # return NodeGroup if self has a node group parent; otherwise nil
      def node_group_parent?
        node_group(raise_errors: false)
      end

      # return NodeGroup
      def node_group_parent
        node_group(raise_errors: true)
      end

      def soft_delete()
        self.update(:ng_member_deleted => true)
      end

      private

      def node_group(opts = {})
        @node_group ||= get_node_group(opts)
      end

      def get_node_group(opts = [])
        sp_hash = {
          cols: [:id, :node_group],
          filter: [:eq, :node_id, id()]
        }
        
        nodes = Model.get_objs(model_handle(:node_group_relation), sp_hash).map { |r| r[:node_group] }
        if assembly_id = get_field?(:assembly_id)
          filtered_nodes = nodes.select { |node| node[:assembly_id] == assembly_id }
          nodes = filtered_nodes unless filtered_nodes.empty?
        else
          filtered_nodes = nodes.select { |node| ! node[:assembly_id].nil? }
          nodes = filtered_nodes unless filtered_nodes.empty?
        end

        unless nodes.size == 1
          if opts[:raise_errors].nil? or opts[:raise_errors]
            fail Error.new("Unexpected that rows.size (#{nodes.size}) does not equal 1")
          end
        end

        if ret = nodes.first
          fail Error.new("Unexpected that node (#{ret.inspect}) connected to node group member (#{get_field?(:display_name)}) is not a node group") unless ret.is_node_group?
          NodeGroup.create_as(ret)
        end
      end

    end
  end
end

# TODO: dtermine whether to handle ng component to ng member using links or by having processing
# change to node group component specially, which is implemented now
# This would replace no op above
#      def clone_post_copy_hook(clone_copy_output,opts={})
# add attribute links between source components and the ones generated
#        level = 1
#        cols_to_get = [:id,:group_id,:display_name,:ancestor_id]
#        cloned_attributes = clone_copy_output.children_objects(level,:attribute, :cols => cols_to_get)
#        link_node_group_attributes_to_clone_ones(cloned_attributes)
#      end
#     private
#      def link_node_group_attributes_to_clone_ones(cloned_attributes)
#        return if cloned_attributes.empty?
#        attr_mh = cloned_attributes.first.model_handle()
#        # TODO:
#      end
#    end
#  end
#end
