module DTK; class Node
  module Delete
    module Mixin
      # This wil be called only when self is non node group (i.e., top level node or target ref)
      def destroy_and_delete(opts = {})
        if is_node_group?()
          # TODO: support this; one way is to case on whether it has any members and if not
          # allow it to be deleted; and if members indicate the syntax to delete an individual member"
          fail ErrorUsage.new('Not supported: deleting a node group; its members can be deleted')
        end
        if is_target_ref?
          destroy_and_delete__target_ref(opts)
        else
          destroy_and_delete__top_level_node(opts)
        end
      end

      def destroy_and_reset(target_idh)
         fail ErrorUsage.new('Command Not Supperetd')
# TODO: DTK-1857
if is_node_group?() || is_target_ref?()
  fail ErrorUsage.new('destroy_and_reset_nodes not supported for service instances with node groups')
end

        if CommandAndControl.destroy_node?(self, reset: true)
          Model.delete_instance(target_ref.id_handle) if target_ref
          StateChange.create_pending_change_item(new_item: id_handle(), parent: target_idh)
        end
        update_agent_git_commit_id(nil)
        attribute.clear_host_addresses()
      end

      def delete_object(opts = {})
        if target_ref_idh = opts[:delete_target_ref]
          Model.delete_instance(target_ref_idh)
        end

        update_dangling_links()

        if is_target_ref?()
          # This wil be a node group member; need to bump down is assocaited node groups cardinality
          node_group_member = ServiceNodeGroup::NodeGroupMember.create_as(self)
          node_group_member.bump_down_associated_node_group_cardinality()
        end

        if opts[:update_task_template]
          unless assembly = opts[:assembly]
            fail Error.new('If update_task_template is set, :assembly must be given as an option')
          end
          update_task_templates_when_deleted_node?(assembly)
        end
        Model.delete_instance(id_handle())
        true
      end

      private

      def destroy_and_delete__target_ref(opts = {})
        suceeeded = true
        if is_target_ref?(not_deletable: true)
          # no op
          return suceeeded
        end
        # check the reference count on the target ref; if one (or less can delet) since this
        # is being initiated by a node group or top level node pointing to it
        # if more than 1 reference count than succeed with no op
        ref_count = TargetRef.get_reference_count(self)
        if ref_count < 2
          execute_destroy_and_delete(opts)
        else
          # no op
          true
        end
      end

      def destroy_and_delete__top_level_node(opts)
        # see if there are any target refs this points to this
        # if none then destroy and delete
        # if 1 then check reference count
        # since this is not anode group target_refs_info should not have size greater than 1
        target_refs_info = TargetRef.get_linked_target_refs_info(self)
        if target_refs_info.empty?
          execute_destroy_and_delete(opts)
        elsif target_refs_info.size == 1
          target_ref_info = target_refs_info.first
          opts_delete = opts
          target_ref = target_ref_info.target_ref
          if target_ref && target_ref_info.ref_count == 1
            # this means to delete target ref also
            opts_delete.merge(delete_target_ref: target_ref.id_handle())
          end
          execute_destroy_and_delete(opts)
        else
          Log.error("Unexpected that (#{inspect}) is linked to more than 1 target refs")
          delete_object(opts)
        end
      end

      def execute_destroy_and_delete(opts = {})
        suceeeded = CommandAndControl.destroy_node?(self)
        return false unless suceeeded
        delete_object(opts)
      end

      def update_task_templates_when_deleted_node?(assembly)
        # TODO: can be more efficient if have Task::Template method that takes node and deletes all teh nodes component in bulk
        sp_hash = {
          #:only_one_per_node,:ref are put in for info needed when getting title
          cols: [:id, :display_name, :node_node_id, :only_one_per_node, :ref],
          filter: [:eq, :node_node_id, id()]
        }
        components = Component::Instance.get_objs(model_handle(:component), sp_hash)
        components.map { |cmp| Task::Template::ConfigComponents.update_when_deleted_component?(assembly, self, cmp) }
      end
    end
  end
end; end
