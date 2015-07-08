module DTK
  class ServiceNodeGroup
    class NodeGroupMember < ::DTK::Node
      def self.model_name
        :node
      end
      def bump_down_associated_node_group_cardinality
        service_node_group().bump_down_cardinality()
      end

      def clone_post_copy_hook(_clone_copy_output,_opts={})
        # no op
      end

      private

      def service_node_group
        return @service_node_group if @service_node_group
        sp_hash = {
          cols: [:id,:service_node_group],
          filter: [:eq,:node_id,id()]
        }
        nodes = Model.get_objs(model_handle(:node_group_relation),sp_hash).map{|r|r[:service_node_group]}
        unless nodes.size == 1
          raise Error.new("Unexpected that rows.size (#{nodes.size}) does not equal 1")
        end
        ret = nodes.first
        unless ret.is_node_group?()
          raise Error.new("Unexpected that node (#{ret.inspect}) connected to node group member (#{get_field?(:display_name)}) is not a node group")
        end
        @service_node_group = ServiceNodeGroup.create_as(ret)
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
