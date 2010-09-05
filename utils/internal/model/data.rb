module XYZ
  module ModelDataClassMixins
    def get_objects(relation_type,c,where_clause=nil,opts={})
      where_clause_x,parent_id = SQL.find_and_remove_parent_id(where_clause)
      if parent_id
        parent_id_handle = IDHandle[:c => c, :guid => parent_id]
        @db.get_objects_wrt_parent(relation_type,parent_id_handle,where_clause_x,opts)
      else
        @db.get_objects(relation_type,c,where_clause,opts)
      end
    end

    def get_objects_just_sequel_dataset(relation_type,c,where_clause=nil,opts={})
      get_objects(relation_type,c,where_clause,opts.merge({:return_just_sequel_dataset => true}))
    end

    def get_factory_id_handle(parent_id_handle,relation_type=nil)
      IDInfoTable.get_factory_id_handle(parent_id_handle,relation_type || @relation_type)
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
      @db_rel[:virtual_columns].has_key?(x)
    end
  end
  #End ModelDataClassMixins

  #instance mixins
  module ModelDataInstanceMixins

    def update(scalar_assignments,opts={})
      scalar_assignments.each{|k,v| self[k] = v}
      self.class.update_instance(id_handle,scalar_assignments,opts)
    end

    def get_directly_contained_objects(child_relation_type,where_clause={})
      self.class.get_objects_wrt_parent(child_relation_type,id_handle,where_clause)
    end

    def get_directly_contained_object_ids(child_relation_type,where_clause={})
      self.class.get_object_ids_wrt_parent(child_relation_type,id_handle,where_clause)
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

    def get_parent_object(opts={})
      self.class.get_parent_object(id_handle,opts)
    end

    def get_parent_id_info()
      self.class.get_parent_id_info(id_handle)
    end

   protected

    def id_handle()
      raise Error.new("id_handle not stored with object") if @id_handle.nil?
      @id_handle
    end

   private

    def ret_id_handle_from_db_id(db_id,relation_type)
      IDHandle[:c => @c, :guid => IDInfoTable.ret_guid_from_db_id(db_id,relation_type)]
    end

    def get_object_from_db_id(db_id,relation_type,opts={})
      self.class.get_object(ret_id_handle_from_db_id(db_id,relation_type))
    end
  end
  #End ModelDataInstanceMixins

end
