#TBD: just skeleton of more complex set of lasses; which wil factored in what, how, where: what objects to gather, how to do it and where to put them in the project
module XYZ
  class DataSource < Model
    set_relation_name(:data_source,:data_source)
    class << self
      def up()
        column :source_handle, :json
        column :update_policy, :varchar, :size =>25 #indicates whether inventory is updated onmanual, automatic, user_approval_for_delete, user_approval_for_add, user_approval_for_change (plus automitcally delete objects not put in thru our tool  
        column :filter, :json #intended to capture the "what"
        column :polling_policy, :json
        foreign_key :polling_task_id, :task, FK_SET_NULL_OPT
        column :objects_location, :json #intnded top capture the where such as put in project top level or in container or associate with some group or tag
        many_to_one :project
      end
      #actions

      #TBD: stub now; fil in defaults if dont have paramters
      Data_source_defaults = {:filter => {:types => [:node]}}
      def create(container_handle_id,ref,hash_content={})
        factory_id_handle = get_factory_id_handle(container_handle_id)
        id_handle = get_child_id_handle_from_qualified_ref(factory_id_handle,ref)
        raise Error.new("data source #{ref} exists already") if exists? id_handle

        hash_with_defaults = Hash.new
        [:filter,:source_handle,:update_policy,:polling_policy,:objects_location].each do |key|
          v = hash_content[key] || Data_source_defaults[key] 
          hash_with_defaults[key] = v if v
        end
        create_from_hash(container_handle_id, {:data_source => {ref => hash_with_defaults}})
        container_handle_id
      end
    end
  end
end
