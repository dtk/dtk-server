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

          if uses_multiple_level_iteration()
            multiple_level_iteration(container_id_handle,marked)
          else
            single_level_iteration(container_id_handle,marked)
          end
          
          delete_unmarked(container_id_handle,marked)
        end

       private
       #filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
        def filter(ds_attr_hash)
          ds_attr_hash
        end

        def object_type()
          relation_type().to_s()
        end

        def uses_multiple_level_iteration()
          self.method("get_objects__#{object_type}").arity == 1
        end

        def multiple_level_iteration(container_id_handle,marked)
          send("get_list__#{object_type}".to_sym).each() do |source_name|
            send("get_objects__#{object_type}".to_sym,source_name).each do |ds_attr_hash|
              discover_and_update_item(container_id_handle,ds_attr_hash,marked) 
            end
          end
        end

        def single_level_iteration(container_id_handle,marked)
          send("get_objects__#{object_type}".to_sym).each do |ds_attr_hash|
            discover_and_update_item(container_id_handle,ds_attr_hash,marked) 
          end
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

          Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
        end

        def create_object(container_id_handle,ds_attr_hash)
          obj = {:ds_key => ds_key_value(ds_attr_hash)}
          obj.merge! :ds_attributes => filter(ds_attr_hash)
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
          relative_unique_key = unique_keys(ds_attr_hash)
          ([ds_type().to_s] + relative_unique_key).inspect
        end

        def ref(ds_attr_hash)
          relative_distinguished_name(ds_attr_hash)
        end
        def relation_type
          Aux.underscore(Aux.demodulize(self.to_s)).to_sym
        end
      end
    end
end


