module XYZ
  class DataSourceAdapter
    def self.create(ds_object)
      obj_type = ds_object[:obj_type].to_s
      ds_name = ds_object[:ds_name].to_s
      src = ds_object[:source_obj_type] ? ds_object[:source_obj_type].to_s : nil 
      rel_path = "#{ds_name}/#{obj_type}#{src ? "__" + src : ""}"
      begin 
        require File.expand_path(rel_path, File.dirname(__FILE__))
       rescue Exception
        raise Error.new("Adapter file to process object #{obj_type} for data source #{ds_name} #{src ? "(using source object #{src}) " : ""} does not exist")
      end

      base_class = DSAdapter.const_get Aux.camelize(ds_name)
      adaper_class = base_class.const_get Aux.camelize("#{obj_type}#{src ? "_" + src : ""}")
      adaper_class.new(obj_type,ds_name,src)
    end

    def discover_and_update(container_id_handle,ds_object)
      marked = Array.new

      if uses_multiple_level_iteration()
        multiple_level_iteration(container_id_handle,marked)
      else
        single_level_iteration(container_id_handle,marked)
      end
          
      delete_unmarked(container_id_handle,marked)
    end

   private
    def initialize(obj_type,ds_name,source_obj_type)
      @obj_type = obj_type
      @ds_name = ds_name
      @source_obj_type = source_obj_type
    end

    #filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
    def filter(ds_attr_hash)
      ds_attr_hash
    end

    #normalize gets ovewritten if have any generic properties
    def normalize(ds_attr_hash)
      {}
    end

    def uses_multiple_level_iteration()
      self.method(get_objects()).arity == 1
    end

    def multiple_level_iteration(container_id_handle,marked)
      send(get_list()).each() do |source_name|
        send(get_objects(),source_name).each do |ds_attr_hash|
          discover_and_update_item(container_id_handle,ds_attr_hash,marked) 
        end
      end
    end

    def single_level_iteration(container_id_handle,marked)
      send(get_objects()).each do |ds_attr_hash|
        discover_and_update_item(container_id_handle,ds_attr_hash,marked) 
      end
    end

    def get_list()
      "get_list__#{@obj_type}".to_sym
    end
    def get_objects()
      src = @source_obj_type 
      "get_objects__#{@obj_type}#{src ? "__" + src : ""}".to_sym
    end

    def discover_and_update_item(container_id_handle,ds_attr_hash,marked)
      return nil if ds_attr_hash.nil?
      marked << ds_key_value(ds_attr_hash)
      id_handle = find_object_id_handle(container_id_handle,ds_attr_hash)
      if id_handle
        update_object(container_id_handle,id_handle,ds_attr_hash)
      else
        create_object(container_id_handle,ds_attr_hash)
      end
    end
        
    def delete_unmarked(container_id_handle,marked)
      marked_disjunction = nil
      marked.each do |ds_key|
        marked_disjunction = SQL.or(marked_disjunction,{:ds_key => ds_key})
      end
      where_clause = SQL.not(marked_disjunction)
      where_clause = SQL.and(where_clause,:ds_source => @source_obj_type) if @source_obj_type
      Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
    end

    def create_object(container_id_handle,ds_attr_hash)
      obj = {:ds_key => ds_key_value(ds_attr_hash)}
      obj.merge! :ds_attributes => filter(ds_attr_hash)
      obj.merge! normalize(ds_attr_hash)
      obj.merge!({:ds_source => @source_obj_type}) if @source_obj_type
      Object.input_into_model(container_id_handle,{relation_type() => {ref(ds_attr_hash) => obj}})
    end

    def update_object(container_id_handle,id_handle,ds_attr_hash)
      #TBD: just stub; real version should keep same id
      Object.delete_instance(id_handle)
      create_object(container_id_handle,ds_attr_hash)
    end

    def find_object_id_handle(container_id_handle,ds_attr_hash)
      where_clause = {:ds_key => ds_key_value(ds_attr_hash)}
      id = Object.get_object_ids_wrt_parent(relation_type(),container_id_handle,where_clause).first
      id ? IDHandle[:guid => id,:c => container_id_handle[:c]] : nil
    end

    def relation_type
      @obj_type.to_sym
    end

    def ds_key_value(ds_attr_hash)
      relative_unique_key = unique_keys(ds_attr_hash)
      ([@ds_name.to_sym] + relative_unique_key).inspect
    end

    def ref(ds_attr_hash)
      relative_distinguished_name(ds_attr_hash)
    end
  end
end


