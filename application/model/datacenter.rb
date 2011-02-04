module XYZ
  class Datacenter < Model
#    set_relation_name(:datacenter,:datacenter)
    
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
      level = 1
      node_idhs = clone_copy_output.children_id_handles(level,:node)
      node_new_items = node_idhs.map{|idh|{:new_item => idh, :parent => target_id_handle}}
      return if node_new_items.empty?
      node_sc_idhs = StateChange.create_pending_change_items(node_new_items)

      indexed_node_info = Hash.new #TODO: may have state create this as output
      node_sc_idhs.each_with_index{|sc_idh,i|indexed_node_info[node_idhs[i].get_id()] = sc_idh}

      level = 2
      component_new_items = clone_copy_output.children_hash_form(level,:component).map do |child_hash| 
        {:new_item => child_hash[:id_handle], :parent => indexed_node_info[child_hash[:clone_parent_id]]}
      end
      return if component_new_items.empty?
      StateChange.create_pending_change_items(component_new_items)
    end
  end
end

