module DTK; class LinkDefContext
  class NodeMappings
    class NodeGroup < ::DTK::ServiceNodeGroup
      def self.model_name()
        :node
      end

      def self.create_as(node,target_refs)
        super(node).set_target_refs!(target_refs)
      end

      def set_target_refs!(target_refs)
        @target_refs = target_refs
        self
      end

      def get_node_attributes()
        @node_attributes ||= get_node_attributes_aux()
      end

     private
      def get_node_attributes_aux()
        x = self.class.get_attributes_to_copy_to_target_refs([id_handle()])
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
