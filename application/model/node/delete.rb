module DTK
  class Node
    module DeleteMixin
      def destroy_and_delete(opts={})
        suceeeded = true
        destroy_node = false

        target_ref_info = get_linked_target_ref_info()
        if target_ref_info.ref_count < 2
          suceeeded = CommandAndControl.destroy_node?(self)
        end
        
        if suceeeded
          opts_delete = opts
          if target_ref.ref_count == 1
            opts_delete.merge(:delete_target_ref => target_refs.first.id_handle())
          end
          delete_object(opts_delete)
        end
        suceeeded
      end
      
      def destroy_and_reset(target_idh)
        if get_linked_target_ref_info().ref_count < 2
          if CommandAndControl.destroy_node?(self,:reset => true)
            StateChange.create_pending_change_item(:new_item => id_handle(), :parent => target_idh)
          end
        end
      end
      
      def delete_object(opts={})
        if target_ref_idh = opts[:delete_target_ref]
          Model.delete_instance(target_ref_idh)
        end
        update_dangling_links()
        if opts[:update_task_template]
          unless assembly = opts[:assembly]
            raise Error.new("If update_task_template is assembled :assembly must be given as an option")
          end
          update_task_templates_when_deleted_node?(assembly)
        end
        Model.delete_instance(id_handle())
        true
      end

     private
      def update_task_templates_when_deleted_node?(assembly)
        # TODO: can be more efficient if have Task::Template method that takes node and deletes all teh nodes component in bulk
        sp_hash = {
          #:only_one_per_node,:ref are put in for info needed when getting title
          :cols => [:id, :display_name, :node_node_id,:only_one_per_node,:ref],
          :filter => [:eq, :node_node_id, id()]
        }
        components = Component::Instance.get_objs(model_handle(:component),sp_hash)
        components.map{|cmp|Task::Template::ConfigComponents.update_when_deleted_component?(assembly,self,cmp)}
      end
    end
  end
end
