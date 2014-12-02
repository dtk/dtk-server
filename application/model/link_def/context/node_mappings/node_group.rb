module DTK; class LinkDefContext
  class NodeMappings
    class NodeGroup < ::DTK::NodeGroup
      def self.create_as(node,target_refs)
        @target_refs = target_refs
        super(node)
      end
      def get_node_attributes!()
        @node_attributes ||= get_node_group_attributes()
      end
      
     private
      def get_node_attributes(node_mapping_nodegroup)
        target_ref_ids = @target_refs.map{|n|n.id} 
        sp_hash = {
          :cols => [:id,:group,:display_name,:node_node_id],
          :filter => [:oneof, :node_node_id,target_ref_ids]
        }
        attr_mh = model_handle(:attribute)
        Model.get_objs(attr_mh,sp_hash)
      end
    end
  end
end; end
