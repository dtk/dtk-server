module DTK; class Attribute
  class SpecialProcessing
    class Update < self
      def self.handle_special_processing_attributes(existing_attrs,ndx_new_vals)
        existing_attrs.each do |attr|
          if needs_special_processing?(attr)
            new_val = ndx_new_vals[attr[:id]]
            attr_info(attr)[:proc].call(attr,new_val)
          end
        end
      end
     private
      def self.ret_special_processing_info()
        SpecialProcessingInfo
      end
      SpecialProcessingInfo = {
        :memory_size => {
          :filter => lambda{|a|a[:node_node_id]},
          :proc => lambda{|a,v|MemorySize.process(a,v)}
        },
        :os_identifier =>{
          :filter => lambda{|a|a[:node_node_id]},
          :proc => lambda{|a,v|OsIdentifier.process(a,v)}
        } 
      }
      class OsIdentifier < self
        def self.process(attr,new_val)
          os_identifier = new_val
          node, target = get_node_and_target(attr)
          image_id, os_type = Node::Template.find_image_id_and_os_type(os_identifier,target)
          unless image_id
            target.update_object!(:display_name,:iaas_type,:iaas_properties)
            raise ErrorUsage.new("Cannot find image_id from os identifier (#{os_identifier}) in target (#{target[:display_name]})")
          end
          node.update_external_ref_field(:image_id,image_id)
          node.update(:os_type => os_type)
        end
       private
        def self.get_node_and_target(attr)
          node = get_node(attr)
          [node,node.get_target()]
        end
      end

      class MemorySize < self
        def self.process(attr,new_val)
          get_node(attr).update_external_ref_field(:size,new_val)
        end
      end

      def self.get_node(attr)
        node_idh = attr.model_handle(:node).createIDH(:id => attr[:node_node_id])
        node_idh.create_object()
      end
    end
  end
end; end
