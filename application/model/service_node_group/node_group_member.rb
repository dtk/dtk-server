module DTK
  class ServiceNodeGroup
    class NodeGroupMember < ::DTK::Node
      def self.model_name()
        :node
      end

      # TODO: dtermine whether to handle ng component to ng member using links or by having processing 
      # change to node group component specially, which is implemented now
      def clone_post_copy_hook(clone_copy_output,opts={})
        # add attribute links between source components and the ones generated
#        level = 1
#        cols_to_get = [:id,:group_id,:display_name,:ancestor_id] 
#        cloned_attributes = clone_copy_output.children_objects(level,:attribute, :cols => cols_to_get)
#        link_node_group_attributes_to_clone_ones(cloned_attributes)
      end
     private
#      def link_node_group_attributes_to_clone_ones(cloned_attributes)
#        return if cloned_attributes.empty?
#        attr_mh = cloned_attributes.first.model_handle()
#        # TODO:
#      end
    end
  end
end
