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
      def initialize(attr,new_val)
        @attr = attr
        @new_val = new_val
      end

      class GroupCardinality < self
        def initialize(attr,new_val)
          super(attr,new_val.to_i)
        end
        def process()
          @attr.update_object!(:value_asserted,:node_node_id)
          existing_val = (@attr[:value_asserted]||0).to_i
          if @new_val < existing_val
            raise ErrorUsage.new("Use delete-node on individual members to reduce the size of the group")
          elsif @new_val == existing_val
            raise ErrorUsage.new("Value set equals existing value (#{existing_val.to_s})")
          end
          node_group = @attr.get_service_node_group(:cols => [:id,:group_id,:display_name,:datacenter_datacenter_id,:assembly_id])
          node_group.add_group_members(@new_val)
        end
      end

      class OsIdentifier < self
        def process()
          os_identifier = @new_val
          node, target = get_node_and_target()
          image_id, os_type = Node::Template.find_image_id_and_os_type(os_identifier,target)
          unless image_id
            target.update_object!(:display_name,:iaas_type,:iaas_properties)
            raise ErrorUsage.new("Cannot find image_id from os identifier (#{os_identifier}) in target (#{target[:display_name]})")
          end
          node.update_external_ref_field(:image_id,image_id)
          node.update(:os_type => os_type)
        end
       private
        def get_node_and_target()
          node = @attr.get_node(:cols => [:id,:group_id,:display_name,:datacenter_datacenter_id])
          [node,node.get_target()]
        end
      end

      class MemorySize < self
        def process()
          node = @attr.get_node(:cols => [:id,:group_id,:display_name,:external_ref])
          node.update_external_ref_field(:size,@new_val)
        end
      end
    end
  end
end; end
