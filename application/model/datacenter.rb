module XYZ
  class Datacenter < Model
    set_relation_name(:datacenter,:datacenter)
    def self.up()
      # no table specific columns (yet)
      one_to_many :data_source, :node, :state_change, :node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway, :component
    end
    
    #### actions
    def self.clone_post_copy_hook(clone_copy_output,target_id_handle,opts={})
      case clone_copy_output.model_name()
       when :component 
        clone_post_copy_hook__component(clone_copy_output,target_id_handle,opts)
       else #TODO: catchall taht will be expanded
        new_id_handle = clone_copy_output.id_handles.first
        StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => target_id_handle)
      end
    end
   private
    def self.clone_post_copy_hook__component(clone_copy_output,target_id_handle,opts)
      #TODO: right now this wil be just a composite component and clone_copy_output will be off form assembly - nodee - component
      #TODO: may put nodes under "install of assembly"
      node_new_items = Array.new

      level = 1
      clone_copy_output.children_id_handles(level,:node).each do |idh|
        node_new_items << {:new_item => idh, :parent => target_id_handle}
      end
      unless node_new_items.empty?
        sc_idhs = StateChange.create_pending_change_items(node_new_items)
        pp [:sc_ihds,sc_idhs]
      end
      #TODO: now process component installs
    end
  end
end

