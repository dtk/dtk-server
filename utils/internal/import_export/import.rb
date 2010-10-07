module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    #TBD: assumption is that target_id_handle is in uri form
    def import_objects_from_file(target_id_handle,json_file,opts={})
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      create_prefix_object_if_needed(target_id_handle,opts)
      hash_content = Aux::hash_from_file_with_json(json_file) 
      if hash_content
        unless target_id_handle.is_top?
          input_into_model(target_id_handle,hash_content) 
        else
          hash_content.each do |relation_type,info|
            #TODO: use TerstURI fncs for this parsing
            ref = info.keys.first
            child_target_id_handle = IDHandle[:c => target_id_handle[:c], :uri => "/#{relation_type}/#{ref}"]
            child_hash_content = info.values.first
            create_prefix_object_if_needed(child_target_id_handle,opts)
            input_into_model(child_target_id_handle,child_hash_content)
          end
        end
      end
    end
    def create_prefix_object_if_needed(target_id_handle,opts={})
      return nil if exists? target_id_handle 
      if opts[:delete]
        Log.info("deleting #{target_id_handle}")
        delete_instance(target_id_handle)
      end
      create_simple_instance?(target_id_handle[:uri],target_id_handle[:c])    
    end
  end
end

