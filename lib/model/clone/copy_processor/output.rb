module DTK
  class Clone
    class CopyProcessor
    # TODO: slight refactor of Output so each child is of form {:parent => <parent>,:child => Output>}
      class Output
        def initialize(source_obj,opts={})
          @source_object = source_obj
          @id_handles = Array.new
          @objects = nil
          @children = Hash.new
          # TODO: more efficient than making this Boolean is structure that indicates what depth to save children 
          @include_children = opts[:include_children]
          @ret_new_obj_with_cols = opts[:ret_new_obj_with_cols]
        end
        
        attr_reader :source_object, :id_handles, :ret_new_obj_with_cols, :objects
        def model_name()
        # all id handles wil be of same type
          @id_handles.first && @id_handles.first[:model_name]
        end
        
        def get_children_object_info(level,model_name)
          ((@children[level]||{})[model_name]||[]).map{|x|x[:obj_info]}
        end

        def children_objects(level,model_name,opts={})
          if hash_form = children_hash_form(level,SubClassRels[model_name]||model_name)
            ret = hash_form.map{|r|r[:id_handle].create_object(:model_name => model_name).merge(r[:obj_info])}
            if opts[:cols]
              Model.add_fields!(ret,opts[:cols])
            end
            ret
          end
        end
        SubClassRels = {
          :component_instance => :component
        }

        def children_hash_form(level,model_name)
          unless @include_children
            Log.error("children should not be called on object with @include_children set to false")
            return Array.new
          end
          (@children[level]||{})[model_name]||[]
        end

        def children_id_handles(level,model_name)
          children_hash_form(level,model_name).map{|child_hash|child_hash[:id_handle]}
        end

        def assembly?(opts={})
          objects && objects.first && objects.first.assembly?(opts)
        end

        def set_new_objects!(objs_info,target_mh)
          @id_handles = Model.ret_id_handles_from_create_returning_ids(target_mh,objs_info)
          if @ret_new_obj_with_cols
            @objects = Array.new
            objs_info.each_with_index do |obj_hash,i|
              obj = @id_handles[i].create_object()
              @ret_new_obj_with_cols.each{|col|obj[col] ||= obj_hash[col] if obj_hash.has_key?(col)}
              @objects << obj
            end
          end
          @id_handles
        end

        def add_id_handle(id_handle)
          @id_handles  << id_handle
        end

        def add_new_children_objects(objs_info,target_mh,parent_col,level)
          child_idhs = Model.ret_id_handles_from_create_returning_ids(target_mh,objs_info)
          return child_idhs unless @include_children
          level_p =  @children[level] ||= Hash.new
          objs_info.each_with_index do |child_obj,i|
            idh = child_idhs[i] 
            children = level_p[idh[:model_name]] ||= Array.new
            # clone_parent_id can differ from parent_id if for example node is under an assembly
            children << {:id_handle => idh, :clone_parent_id => child_obj[parent_col], :obj_info => child_obj}
          end
          child_idhs
        end
      end
    end
  end
end

