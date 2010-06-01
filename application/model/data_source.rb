module XYZ
  class DataSource < Model
    set_relation_name(:data_source,:data_source)
    class << self
      def up()
        column :source_handle, :json
        column :update_policy, :varchar, :size =>25 #indicates whether inventory is updated onmanual, automatic, user_approval_for_delete, user_approval_for_add, user_approval_for_change  
        column :filter, :json
        column :polling_policy, :json
        foreign_key :polling_task_id, :task, FK_SET_NULL_OPT
        column :objects_location, :json
        many_to_one :project
      end
      #actions
=begin
      def find_or_create(container_handle_id,ref,hash_content={})
        factory_id_handle = get_factory_id_handle(container_handle_id)
        #since passing ref for qualified_ref param assuming that ref is unique 
        id_handle = get_child_id_handle_from_qualified_ref(factory_id_handle,ref)
        return get_object(id_handle) if exists? id_handle
      end
=end        
    end
  end
end
