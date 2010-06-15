require File.expand_path('dsl_processor', File.dirname(__FILE__))
module XYZ
  class DataSourceAdapter
    extend DataTranslationClassMixin
    def self.create(ds_object)
      obj_type = ds_object[:obj_type].to_s
      ds_name = ds_object[:ds_name].to_s
      src = ds_object[:source_obj_type] ? ds_object[:source_obj_type].to_s : nil 
      rel_path = "#{ds_name}/#{obj_type}#{src ? "__" + src : ""}"
      begin 
        file_path = File.expand_path(rel_path, File.dirname(__FILE__)) 
        require file_path
       rescue Exception => e 
        raise Error.new("Adapter file to process object #{obj_type} for data source #{ds_name} #{src ? "(using source object #{src}) " : ""} does not exist") unless File.exists?(file_path + ".rb")
        raise e
      end

      base_class = DSAdapter.const_get Aux.camelize(ds_name)
      adaper_class = base_class.const_get Aux.camelize("#{obj_type}#{src ? "_" + src : ""}")
      adaper_class.new(obj_type,ds_name,src)
    end

    def discover_and_update(container_id_handle,ds_object)
      #TBD: might set in initialization this object can only be associated with one container id
      @container_id_handle = container_id_handle
      marked = Array.new
      context = Hash.new
      get_and_update_objects(container_id_handle,marked,context)          
      delete_unmarked(container_id_handle,marked,context)
    end

   private
    def initialize(obj_type,ds_name,source_obj_type)
      @container_id_handle = nil
      @obj_type = obj_type
      @ds_name = ds_name
      @source_obj_type = source_obj_type
    end

    #filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
    def filter(source_obj)
      source_obj
    end


    def get_and_update_objects(container_id_handle,marked,context)          
      method_name = "get_objects__#{@obj_type}#{@source_obj_type ? "__" + @source_obj_type : ""}".to_sym
      context[:source_is_complete] = true
      send(method_name) do |source_obj|
        discover_and_update_item(container_id_handle,source_obj,marked) 
      end
    end

    def discover_and_update_item(container_id_handle,source_obj,marked)
      return nil if source_obj.nil?
      marked << ds_key_value(source_obj)
      db_update_hash = ret_db_update_hash(container_id_handle,source_obj)
      Object.input_into_model(container_id_handle,db_update_hash)
    end

    def ret_db_update_hash(container_id_handle,source_obj)
      obj = self.class.normalize(source_obj)
      obj[:ds_attributes] = filter(source_obj)
      obj[:ds_key] = ds_key_value(source_obj)
      obj[:ds_source] = @source_obj_type if @source_obj_type      
      ret = DBUpdateHash.create_with_auto_vivification()
      ret[relation_type()][ref(source_obj)]= obj
      ret.freeze
    end

        
    #TBD: see if can refactor and have this subsumed by logic in db update
    def delete_unmarked(container_id_handle,marked,context)
      return nil unless context[:source_is_complete]
      constraints = self.class.top_level_completeness_constraints
      return nil if constraints.nil?
      marked_disjunction = nil
      marked.each do |ds_key|
        marked_disjunction = SQL.or(marked_disjunction,{:ds_key => ds_key})
      end
      where_clause = SQL.not(marked_disjunction)
      where_clause = SQL.and(where_clause,constraints) unless contraints.empty?
      Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
    end

    def relation_type(obj_type = nil)
      (obj_type || @obj_type).to_sym
    end

    def ds_key_value(source_obj)
      relative_unique_key = unique_keys(source_obj)
      qualified_key(relative_unique_key)
    end

    def qualified_key(relative_unique_key,ds_name=nil)
      ([(ds_name||@ds_name).to_sym] + relative_unique_key).inspect
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


