module XYZ
  class DataSourceAdapter
      class << self
        def load_and_ret_adapter_class(obj_type,ds_type)
          require File.expand_path("#{ds_type}/#{obj_type}", File.dirname(__FILE__))
          base_class = DSAdapter.const_get Aux.camelize(ds_type)
          base_class.const_get Aux.camelize(obj_type)
        end

        def discover_and_update(container_id_handle,ds_object)
          marked = Array.new
          if object_paths.size == 1
            (get(object_paths[0])||[]).each do |war_ds_attr_hash|
              discover_and_update_aux(container_id_handle,raw_ds_attr_hash,marked) 
            end
          elsif object_paths.size == 2
            (get(object_paths[0])||[]).each do |obj_ref|
              raw_ds_attr_hash = get(object_paths[1].gsub(%r{\$1},obj_ref))
              discover_and_update_aux(container_id_handle,raw_ds_attr_hash,marked) 
            end
          end
          delete_unmarked(container_id_handle,marked)
        end

       private
       #gets overwritten for non trivial filter
        def filter_attributes()
          nil
        end
       #gets overwritten if one source object gets overwritten to multiple normalized objects
        def maps_to_multiple_objects(v)
          nil
        end
        #gets overwritten if maps_to_multiple_objects is non null
        def unique_key_fields
          nil
        end
        #gets overwritten if maps_to_multiple_objects is non null
        def name_fields
          nil            
        end

        def filter(ds_attr_hash)
         return ds_attr_hash if filter_attributes().nil?
         HashObject.object_slice(ds_attr_hash,filter_attributes())
        end

        def discover_and_update_aux(container_id_handle,raw_ds_attr_hash,marked)
          return nil if raw_ds_attr_hash.nil?
          ds_attr_hash = filter(raw_ds_attr_hash)
          return nil if ds_attr_hash.empty?

          multiple_info = maps_to_multiple_objects(ds_attr_hash)
          (multiple_info||[nil]).each do |multiple_info_hash|
            marked << ds_key_value(ds_attr_hash,multiple_info_hash)
            id_handle = find_object_id_handle(container_id_handle,ds_attr_hash,multiple_info_hash)
            if id_handle
              update_object(container_id_handle,id_handle,ds_attr_hash,multiple_info_hash)
            else
              create_object(container_id_handle,ds_attr_hash,multiple_info_hash)
            end
          end
        end
        
        def delete_unmarked(container_id_handle,marked)
          marked_disjunction = nil
          marked.each do |ds_key|
            marked_disjunction = SQL.or(marked_disjunction,{:ds_key => ds_key})
          end
          where_clause = SQL.not(marked_disjunction)

          Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
        end

        def create_object(container_id_handle,ds_attr_hash,multiple_info_hash=nil)
          obj = {:ds_key => ds_key_value(ds_attr_hash,multiple_info_hash)}
          obj.merge! :ds_attributes => ds_attr_hash
          obj.merge! normalize(ds_attr_hash,multiple_info_hash ? multiple_info_hash.values.first : nil)

          Object.input_into_model(container_id_handle,{relation_type() => {ref(ds_attr_hash,multiple_info_hash) => obj}})
        end

        def update_object(container_id_handle,id_handle,ds_attr_hash,multiple_info_hash=nil)
          #TBD: just stub; real version should keep same id
          Object.delete_instance(id_handle)
          create_object(container_id_handle,ds_attr_hash,multiple_info_hash=nil)
        end

        def find_object_id_handle(container_id_handle,ds_attr_hash,multiple_info_hash=nil)
          where_clause = {:ds_key => ds_key_value(ds_attr_hash,multiple_info_hash)}
          id = Object.get_object_ids_wrt_parent(relation_type(),container_id_handle,where_clause).first
          id ? IDHandle[:guid => id,:c => container_id_handle[:c]] : nil
        end

        def ds_type()
          self.to_s =~ %r{^.+::.+::(.+)::.+$} ? Aux.underscore($1).to_sym : :generic
        end
        def ds_key_value(ds_attr_hash,multiple_info_hash=nil)
          unique_key_flds = multiple_info_hash ? multiple_info_hash.keys :
                  unique_key_fields().map{|k|ds_attr_hash[k]}
          ([ds_type().to_s] + unique_key_flds).inspect
        end

        def ref(ds_attr_hash,multiple_info_hash=nil)
          multiple_info_hash ? multiple_info_hash.keys.first :
            name_fields().map{|k|ds_attr_hash[k]}.join("-")
        end
        def relation_type
          Aux.underscore(Aux.demodulize(self.to_s)).to_sym
        end
      end
    end
end


