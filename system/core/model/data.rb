
#TODO: does this need to have all these 1-to-1 referneces to the function calls?
#can we just move all this into the core model object itself?
module XYZ
  module ModelDataClassMixins
    def get_instance_or_factory(id_handle,href_prefix=nil,opts={})
      @db.get_instance_or_factory(id_handle,href_prefix,opts)
    end

    def get_instance_scalar_values(id_handle,opts={})
      @db.get_instance_scalar_values(id_handle,opts)
    end

    def get_objects(relation_type,c,where_clause=nil)
      @db.get_objects(relation_type,c,where_clause)
    end

    def get_objects_wrt_parent(relation_type,parent_id_handle,where_clause={})
      @db.get_objects_wrt_parent(relation_type,parent_id_handle,where_clause)
    end

    def get_object_ids_wrt_parent(relation_type,parent_id_handle,where_clause={})
      @db.get_object_ids_wrt_parent(relation_type,parent_id_handle,where_clause)
    end

    def get_object(id_handle,opts={})
      @db.get_object(id_handle,opts)
    end

    def get_parent_object(id_handle,opts={})
      @db.get_parent_object(id_handle,opts)
    end

    def exists?(id_handle)
      @db.exists?(id_handle)
    end

    def delete_instance(id_handle,opts={})
      @db.delete_instance(id_handle,opts)
    end

    def create_simple_instance?(new_uri,c,opts={})
      @db.create_simple_instance?(new_uri,c,opts)
    end

    def create_from_hash(factory_id_handle,hash,clone_helper=nil,opts={})
      @db.create_from_hash(factory_id_handle,hash,clone_helper,opts)
    end

    def update_instance(id_handle,scalar_assignments,opts={})
      @db.update_instance(id_handle,scalar_assignments,opts)
    end

    def update_from_hash_assignments(id_handle,hash_assigns,opts)
      @db.update_from_hash_assignments(id_handle,hash_assigns,opts)
    end

    def get_factory_id_handle(parent_id_handle,relation_type)
      unless parent_uri = parent_id_handle[:uri]
        parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
  
        return nil if parent_id_info.nil?
        parent_uri = parent_id_info[:uri]
      end

      factory_uri = RestURI.ret_factory_uri(parent_uri,relation_type)
      IDHandle[:c => parent_id_handle[:c], :uri => factory_uri]
    end

    def get_child_id_handle_from_qualified_ref(factory_id_handle,qualified_ref)
      unless factory_uri = factory_id_handle[:uri]
    	  factory_id_info = IDInfoTable.get_row_from_id_handle(factory_id_handle)
    	  return nil if factory_id_info.nil?
    	  factory_uri = factory_id_info[:uri]
      end

      child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_uri,qualified_ref)
      IDHandle[:c => factory_id_handle[:c], :uri => child_uri]
    end


    #TBD: encapsulate with other fns that make assumption about guid to id relationship
    def get_row_from_id_handle(id_handle,opts={})
      IDInfoTable.get_row_from_id_handle(id_handle,opts)
    end

    def get_child_id_handle(factory_id_handle,child_qualified_ref)
      c = factory_id_handle[:c]
      child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_id_handle[:uri],child_qualified_ref)
      IDHandle[:c => c, :uri => child_uri]
    end

    def is_virtual_column?(x)
      @virtual_columns[x]
    end
  end
  #End ModelDataClassMixins

  #instance mixins
  module ModelDataInstanceMixins

    attr_reader :relation_type

    def initialize(hash_scalar_values,c,relation_type)
      return nil if hash_scalar_values.nil?

      super(hash_scalar_values)

      @c = c
      @relation_type = relation_type
      @id_handle = 
        if hash_scalar_values[:id]
          ret_id_handle_from_db_id(hash_scalar_values[:id],relation_type)
        elsif hash_scalar_values[:uri]
          IDHandle[:c =>c, :uri => hash_scalar_values[:uri]]
        else
          nil
        end
    end

    def [](x)
      return send(x) if self.class.is_virtual_column?(x)
      super(x)
    end

    def update(scalar_assignments,opts={})
      scalar_assignments.each{|k,v| self[k] = v}
      self.class.update_instance(id_handle,scalar_assignments,opts)
    end

    def get_directly_contained_object_ids(child_relation_type)
      self.class.get_object_ids_wrt_parent(child_relation_type,id_handle)
    end

    def object_slice(slice_keys)
      ret = {}
      slice_keys.each{|k| ret[k] = self[k]}
      ret
    end

    def to_s()
     return "UNKNOWN" if self[:display_name].nil?
     self[:display_name]
    end

    def get_qualified_ref()
      #first check if have ref attribute (which is more efficient)
      return DB.ret_qualified_ref_from_scalars(self) if self[:ref]
      IDInfoTable.get_row_from_id_handle(id_handle).ret_qualified_ref()
    end

    def get_obj_name()
      @relation_type
    end

   private

    def ret_id_handle_from_db_id(db_id,relation_type)
      IDHandle[:c => @c, :guid => IDInfoTable.ret_guid_from_db_id(db_id,relation_type)]
    end

    def get_object_from_db_id(db_id,relation_type,opts={})
      self.class.get_object(ret_id_handle_from_db_id(db_id,relation_type))
    end

    def get_parent_object(opts={})
      self.class.get_parent_object(id_handle,opts)
    end
   
    def id_handle()
      raise Error.new("id_handle not stored with object") if @id_handle.nil?
      @id_handle
    end
  end
  #End ModelDataInstanceMixins

end
