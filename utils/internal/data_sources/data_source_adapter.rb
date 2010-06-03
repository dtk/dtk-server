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
            (get(object_paths[0])||[]).each do |ds_attr_hash|
              discover_and_update_aux(container_id_handle,filter(ds_attr_hash),marked) if ds_attr_hash
            end
          elsif object_paths.size == 2
            (get(object_paths[0])||[]).each do |obj_ref|
              ds_attr_hash = get(object_paths[1].gsub(%r{\$1},obj_ref))
              discover_and_update_aux(container_id_handle,filter(ds_attr_hash),marked) if ds_attr_hash
            end
          end
          delete_unmarked(container_id_handle,marked)
        end

       private
       #gets overwritten for non trivial filter
        def filter_attributes()
          nil
        end

        def filter(ds_attr_hash)
         return ds_attr_hash if filter_attributes().nil?
         HashObject.object_slice(ds_attr_hash,filter_attributes())
        end
        def discover_and_update_aux(container_id_handle,ds_attr_hash,marked)
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

          Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
        end

        def create_object(container_id_handle,ds_attr_hash)
          obj = {:ds_key => ds_key_value(ds_attr_hash)}
          obj.merge! :ds_attributes => ds_attr_hash
          obj.merge! normalize(ds_attr_hash)

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

        def ds_type()
          self.to_s =~ %r{^.+::.+::(.+)::.+$} ? Aux.underscore($1).to_sym : :generic
        end
        def ds_key_value(ds_attr_hash)
          ([ds_type().to_s] + unique_key_fields().map{|k|ds_attr_hash[k]}).inspect
        end
        def ref(ds_attr_hash)
          name_fields().map{|k|ds_attr_hash[k]}.join("-")
        end
        def relation_type
          Aux.underscore(Aux.demodulize(self.to_s)).to_sym
        end
      end
    end
end


