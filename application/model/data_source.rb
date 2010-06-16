#TBD: should be moved to core/model
#TBD: just skeleton of more complex set of lasses; which wil factored in what, how, where: what objects to gather, how to do it and where to put them in the project
module XYZ
  class DataSource < Model
    set_relation_name(:data_source,:data_source)
    class << self
      def up()
        column :ds_name, :varchar, :size => 25 
        column :source_handle, :json
        many_to_one :project,:library
        one_to_many :data_source_entry
      end
    end
    #actions
    class << self
      def create(container_handle_id,ref,hash_content={})
        factory_id_handle = get_factory_id_handle(container_handle_id)
        id_handle = get_child_id_handle_from_qualified_ref(factory_id_handle,ref)
        raise Error.new("data source #{ref} exists already") if exists? id_handle
        
        hash_with_defaults = fill_in_defaults(ref.to_sym,hash_content)
        create_from_hash(container_handle_id, {:data_source => {ref => hash_with_defaults}})
        container_handle_id
      end
    end
   private
    #helper fns
    class << self
      DS_defaults = Hash.new #TBD: stub
      def fill_in_defaults(ds_name,hash_content)
        hash_with_defaults = Hash.new
        [:source_handle,:data_source_object].each do |k|
          v = hash_content[k] || DS_defaults[k]
          hash_with_defaults[k] = v if v
        end
        if hash_with_defaults[:data_source_object]
          hash_with_defaults[:data_source_object].each do |obj_type,child_hash_content|
             hash_with_defaults[:data_source_object][obj_type.to_s] = 
              DataSourceObject.fill_in_defaults(ds_name,obj_type.to_sym,child_hash_content)
          end
        end
        hash_with_defaults[:ds_name] = ds_name.to_s
        hash_with_defaults
      end
    end
  end
  class DataSourceEntry < Model
    set_relation_name(:data_source,:entry)
    class << self
      def up()
        column :ds_name, :varchar, :size => 25 #TBD: just passed in for convenient access; 'inherited' from its conatiner
        column :obj_type, :varchar, :size => 25 
        #used when multiple source objects can map to same normaized object such as for ec2 image and instance both map to node
        column :source_obj_type, :varchar, :size => 25 
        column :ds_is_golden_store, :boolean, :default => true
        column :update_policy, :varchar, :size =>25 #indicates whether inventory is updated onmanual, automatic, user_approval_for_delete, user_approval_for_add, user_approval_for_change (plus automitcally delete objects not put in thru our tool  
        column :filter, :json #intended to capture the "what"
        column :polling_policy, :json
        foreign_key :polling_task_id, :task, FK_SET_NULL_OPT
        column :placement_location, :json #intended top capture the where such as put in project top level or in container or associate with some group or tag; default is the container of the root data source object
        many_to_one :data_source, :data_source_entry
        one_to_many :data_source_entry
      end
    end
    #actions
    def discover_and_update()
      #default is to place in conatiner that the data source root sets in
      #TBD: logic to override if @objects_location set
#      default_container_obj = get_parent_object().get_parent_object()
 #     placement_id_handle = default_container_obj.id_handle
      @ds_object_adapter.discover_and_update()
    end

    #helper fns
    def initialize(hash_scalar_values,c,relation_type)
      super(hash_scalar_values,c,relation_type)
      raise Error.new(":obj_type should be in hash_scalar_values") if hash_scalar_values[:obj_type].nil?
      raise Error.new(":ds_name should be in hash_scalar_values") if hash_scalar_values[:ds_name].nil?
      #default is to place in container that the data source root sets in
      #TBD: logic to override if @objects_location set
      default_container_obj = get_parent_object().get_parent_object()
      placement_id_handle = default_container_obj.id_handle
      @ds_object_adapter = DataSourceAdapter.create(self,placement_id_handle)
    end   
    class << self
      DS_object_defaults = {}
      def fill_in_defaults(ds_name,obj_type,hash_content)
        hash_with_defaults = Hash.new
        [:filter,:update_policy,:polling_policy,:objects_location].each do |key|
          v = hash_content[key] || Aux.nested_value(DS_object_defaults,[ds_name,key ])
          hash_with_defaults[key] = v if v
        end
        hash_with_defaults[:ds_name] = ds_name.to_s
        hash_with_defaults[:obj_type] = obj_type.to_s
        hash_with_defaults
      end
    end
  end
end
