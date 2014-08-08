module DTK
  class Node
    module DeleteMixin
      def destroy_and_delete(opts={})
        suceeeded = true
        if is_target_ref?(:not_deletable=>true)
          # no op
          return suceeeded
        end

        if is_target_ref?()
          Log.error("need update logic for target ref; unnecssary to do TargetRef.get_linked_target_ref_info_single_node")
        end

        target_ref_info = TargetRef.get_linked_target_ref_info_single_node(self)
        if target_ref_info.ref_count < 2
          suceeeded = CommandAndControl.destroy_node?(self)
        end

        if suceeeded
          opts_delete = opts
          target_ref = target_ref_info.target_ref
          if target_ref and target_ref_info.ref_count == 1
            opts_delete.merge(:delete_target_ref => target_ref.id_handle())
          end
          delete_object(opts_delete)
        end
        suceeeded
      end
      
      def destroy_and_reset(target_idh)
        target_ref_info = TargetRef.get_linked_target_ref_info_single_node(self)
        target_ref = target_ref_info.target_ref
        if target_ref.nil? or target_ref_info.ref_count < 2
          if CommandAndControl.destroy_node?(self,:reset => true)
            if target_ref
              Model.delete_instance(target_ref.id_handle)
            end
            StateChange.create_pending_change_item(:new_item => id_handle(), :parent => target_idh)
          end
        else
          raise ErrorUsage.new("Cannot destroy_and_reset node (#{get_field?(:display_name)}), which has other assemblies pointing to it")
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
