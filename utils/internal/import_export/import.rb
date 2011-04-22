module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    #TBD: assumption is that target_id_handle is in uri form
    def import_objects_from_file(target_id_handle,json_file,opts={})
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      create_prefix_object_if_needed(target_id_handle,opts)
      hash_content = Aux::hash_from_file_with_json(json_file) 
      return nil unless hash_content
      add_r8meta!(hash_content,opts[:r8meta]) if opts[:r8meta]
      if opts[:add_implementation_file_refs]
        file_ref_info = opts[:add_implementation_file_refs]
        library = file_ref_info[:library]
        base_dir = file_ref_info[:base_directory]
        impl_info = temp_hack_to_get_implementation_info(hash_content,library)
        add_implementation_file_refs!(hash_content,library,impl_info,base_dir)
      end
      global_fks = Hash.new
      unless target_id_handle.is_top?
        global_fks = input_into_model(target_id_handle,hash_content) 
      else
        hash_content.each do |relation_type,info|
          info.each do |ref,child_hash_content|
            child_target_id_handle = IDHandle[:c => target_id_handle[:c], :uri => "/#{relation_type}/#{ref}"]
            create_prefix_object_if_needed(child_target_id_handle,opts)
            r = input_into_model(child_target_id_handle,child_hash_content,:ret_global_fks => true)
            global_fks.merge!(r) if r
          end
        end
      end
      process_global_keys(global_fks,target_id_handle[:c]) unless global_fks.nil? or global_fks.empty?
    end

    def create_prefix_object_if_needed(target_id_handle,opts={})
      return nil if exists? target_id_handle 
      if opts[:delete]
        Log.info("deleting #{target_id_handle}")
        delete_instance(target_id_handle)
      end
      create_simple_instance?(target_id_handle[:uri],target_id_handle[:c])    
    end

    def add_r8meta!(hash,r8meta)
      type = r8meta[:type]
      if type == :yaml
        library = r8meta[:library]
        require 'yaml'
        r8meta[:files].each do |file|
          component_hash = YAML.load_file(file)
          component_hash.each{|k,v|library_components_hash(hash,library)[k] = v}
        end 
      else
        raise Error.new("Type #{type} not supported")
      end
    end

    def temp_hack_to_get_implementation_info(hash,library)
      ret = Hash.new
      library_components_hash(hash,library).each do |cmp,cmp_info|
        next unless cmp_info["implementation"]
        ret[cmp] = cmp.gsub(/__.+$/,"")
      end
      ret
    end
    def add_implementation_file_refs!(hash,library,implementation_info,base_dir)
      component_dirs = implementation_info.values
      files = Array.new
      cur_dir = Dir.pwd
      begin
        Dir.chdir(base_dir)
        files = Dir["{#{component_dirs.join(",")}}/**/*"].select{|item|File.file?(item)}
       ensure
        Dir.chdir(cur_dir)
      end
      files
    end

    def library_components_hash(hash,library)
      hash["library"][library]["component"]
    end
  end
end

