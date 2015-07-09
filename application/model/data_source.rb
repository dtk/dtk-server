# TODO: Marked for removal [Haris] - Looks it is not being used and can be safely removed. But since it is peristed I would like to get second opnion from Rich.
module XYZ
  class DataSource < Model
    #    set_relation_name(:data_source,:data_source)

    ### virtual column defs
    #######################
    ### object access functions

    def self.set_collection_complete(id_handle)
      update_from_hash_assignments(id_handle,last_collection_timestamp: Time.now)
    end

    #######################

    # TODO: see what below we want to keep
    # actions
    class << self
      def create(container_handle_id,ref,hash_content={})
        factory_id_handle = get_factory_id_handle(container_handle_id)
        id_handle = get_child_id_handle_from_qualified_ref(factory_id_handle,ref)
        raise Error.new("data source #{ref} exists already") if exists? id_handle

        hash_with_defaults = fill_in_defaults(ref.to_sym,hash_content)
        create_from_hash(container_handle_id, data_source: {ref => hash_with_defaults})
        container_handle_id
      end
    end

    private

    # helper fns
    class << self
      DS_defaults = {} #TBD: stub
      def fill_in_defaults(ds_name,hash_content)
        hash_with_defaults = {}
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
    attr_reader :ds_object_adapter
    #    set_relation_name(:data_source,:entry)
    # actions
    def discover_and_update
      marked = []
      hash_completeness_info = get_objects() do |source_obj|
        normalize_and_update_db(@container_id_handle,source_obj,marked)
      end
      delete_unmarked(@container_id_handle,marked,hash_completeness_info)
    end

    # helper fns
    include DataSourceAdapterInstanceMixin
    include DataSourceConnectorInstanceMixin

    def initialize(hash_scalar_values,c,relation_type)
      super(hash_scalar_values,c,relation_type)
      raise Error.new(':obj_type should be in hash_scalar_values') if hash_scalar_values[:obj_type].nil?
      raise Error.new(':ds_name should be in hash_scalar_values') if hash_scalar_values[:ds_name].nil?
      # default is to place in container that the data source root sets in
      # TBD: logic to override if @objects_location set
      default_container_obj = get_parent_object().get_parent_object()
      @container_id_handle = default_container_obj.id_handle
      @parent_ds_object = get_parent_object()
      load_ds_connector_class()
      load_ds_adapter_class()
      @ds_connector_instance = nil #gets set subsequently so sharing can be done accross instances
    end

    def obj_type
      self[:obj_type].to_s
    end

    def ds_name
      self[:ds_name].to_s
    end

    def source_obj_type
      self[:source_obj_type] ? self[:source_obj_type].to_s : nil
    end

    def ds_is_golden_store
      self[:ds_is_golden_store]
    end

    class << self
      DS_object_defaults = HashObject.new
      def fill_in_defaults(ds_name,obj_type,hash_content)
        hash_with_defaults = {}
        [:filter,:update_policy,:polling_policy,:objects_location].each do |key|
          v = hash_content[key] || DS_object_defaults.nested_value([ds_name,key])
          hash_with_defaults[key] = v if v
        end
        hash_with_defaults[:ds_name] = ds_name.to_s
        hash_with_defaults[:obj_type] = obj_type.to_s
        hash_with_defaults
      end
    end
  end
end
