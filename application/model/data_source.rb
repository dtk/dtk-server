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
    end
  end
end
