module XYZ
  module DataSourceAdapterInstanceMixin
   private
    def load_ds_adapter_class()
      rel_path = "#{ds_name()}/#{obj_type()}#{source_obj_type() ? "__" + source_obj_type() : ""}"
      begin 
        file_path = File.expand_path(rel_path, File.dirname(__FILE__)) 
        require file_path
       rescue Exception => e 
        raise Error.new("Adapter file to process object #{obj_type()} for data source #{ds_name()} #{source_obj_type() ? "(using source object #{source_obj_type()}) " : ""} does not exist") unless File.exists?(file_path + ".rb")
        raise e
      end

      base_class = DSNormalizer.const_get Aux.camelize(ds_name())
      @ds_object_adapter_class = base_class.const_get Aux.camelize("#{obj_type()}#{source_obj_type() ? "_" + source_obj_type() : ""}")
    end

    def normalize_and_update_db(container_id_handle,source_obj,marked)
      return nil if source_obj.nil?
      marked << ds_key_value(source_obj)
      db_update_hash = ret_db_update_hash(container_id_handle,source_obj)
      Object.input_into_model(container_id_handle,db_update_hash)
    end

    def ret_db_update_hash(container_id_handle,source_obj)
      obj = normalize(source_obj)
      obj[:ds_attributes] = filter(source_obj)
      obj[:ds_key] = ds_key_value(source_obj)
      obj[:ds_source] = source_obj_type() if source_obj_type()      
      ret = DBUpdateHash.create_with_auto_vivification()
      ret[relation_type()][ref(source_obj)]= obj
      ret.freeze
    end

    #Should be overwritten if no dsl
    def normalize(source_obj)
      target_obj = DBUpdateHash.create_with_auto_vivification()
      @ds_object_adapter_class.each do |condition,top_level_assign|
        if condition.evaluate_condition(source_obj)
          top_level_assign.each do |attr,assign|
            process_assignment(target_obj,attr,assign,source_obj) 
          end
        end
      end
      target_obj
    end

   private
    def process_assignment(target_obj,attr,assign,source_obj) 
      if assign.kind_of?(Source)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Function)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Definition)
        process_assignment(target_obj,attr,assign.item,source_obj)
      elsif assign.kind_of?(NestedDefinition)
        target_obj[attr] = assign.normalize(source_obj,@ds_object)
      elsif assign.kind_of?(ForeignKey)
        target_obj[Object.assoc_key(attr)] = assign
      elsif assign.kind_of?(Hash)
        #TBD: use of paranthesis below may be needed because of possible Ruby parser bug
        constraints = (assign.kind_of?(DBUpdateHash) ? assign.constraints : nil)
        target_obj.set_constraints(constraints) if constraints
        #include empty hash if there are contraints associated with it (this wil serve to delet all
        # its peers; only including this conditionally is for optimization
        if assign.empty?
          target_obj[attr] = assign if constraints
        else
          assign.each do |nested_attr,nested_assign|
            process_assignment(target_obj[attr],nested_attr,nested_assign,source_obj)
          end
        end
      else
       target_obj[attr] = assign
      end
    end

    #filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
    def filter(source_obj)
      source_obj
    end

    #TBD: see if can refactor and have this subsumed by logic in db update
    def delete_unmarked(container_id_handle,marked,context)
      return nil unless context[:source_is_complete]
      constraints = @ds_object_adapter_class.top_level_completeness_constraints
      return nil if constraints.nil?
      marked_disjunction = nil
      marked.each do |ds_key|
        marked_disjunction = SQL.or(marked_disjunction,{:ds_key => ds_key})
      end
      where_clause = SQL.not(marked_disjunction)
      where_clause = SQL.and(where_clause,constraints) unless constraints.empty?
      Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
    end

    def relation_type(obj_type_override = nil)
      (obj_type_override || obj_type()).to_sym
    end

    def ds_key_value(source_obj)
      relative_unique_key = unique_keys(source_obj)
      qualified_key(relative_unique_key)
    end

    def qualified_key(relative_unique_key,ds_name_override=nil)
      ([(ds_name_override||ds_name()).to_sym] + relative_unique_key).inspect
    end

    def ref(source_obj)
      relative_distinguished_name(source_obj)
    end

    def find_foreign_key_id(obj_type,relative_unique_key,ds_name=nil)
      where_clause = {:ds_key => qualified_key(relative_unique_key,ds_name)}
      Object.get_object_ids_wrt_parent(relation_type(obj_type),@container_id_handle,where_clause).first
     end
  end
end


