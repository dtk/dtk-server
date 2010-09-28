module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    #TBD: assumption is that target_id_handle is in uri form
    def import_objects_from_file(target_id_handle,json_file,opts={})
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      if exists? target_id_handle 
        if opts[:delete]
          Log.info("deleting #{target_id_handle}")
          delete_instance(target_id_handle)
          create_simple_instance?(target_id_handle[:uri],target_id_handle[:c])
        end
      else
        create_simple_instance?(target_id_handle[:uri],target_id_handle[:c])
      end

      hash_content = Aux::hash_from_file_with_json(json_file) 
      input_into_model(target_id_handle,hash_content) if hash_content
    end
  end
end

