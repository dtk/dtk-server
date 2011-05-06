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
      if opts[:add_implementations]
        impl_info = opts[:add_implementations]
        library = impl_info[:library]
        base_dir = impl_info[:base_directory]
        type = impl_info[:type]
        version = impl_info[:version]
        add_implementations!(hash_content,type,version,library,base_dir)
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
          component_hash.each{|k,v|hash["library"][library]["component"][k] = v}
        end 
      else
        raise Error.new("Type #{type} not supported")
      end
    end

    def add_implementations!(hash,type,version,library,base_dir)
      case type
       when :chef
        ChefImplementation::add_implementations!(hash,version,library,base_dir)
       else
        raise Error.new("Implmentation type #{type} not implemented")
      end
    end

    module ChefImplementation
      def self.add_implementations!(hash,version,library,base_dir)
        file_paths = Array.new
        cur_dir = Dir.pwd
        begin
          Dir.chdir(base_dir)
          file_paths = Dir["**/*"].select{|item|File.file?(item)}
         ensure
          Dir.chdir(cur_dir)
        end
        return if file_paths.empty?

        indexed_file_paths = Hash.new
        file_paths.each do |file_path|
          dir = file_path =~ Regexp.new("(^[^/]+)/") ? $1 : nil
          (indexed_file_paths[dir] ||= Array.new) << file_path
        end
        
        #find components that correspond to an implementation 
        components_hash = hash["library"][library]["component"]
        impl_cookbooks = components_hash.keys.map{|cmp_ref|cookbook_from_component_ref(cmp_ref)}.uniq & indexed_file_paths.keys
        return unless impl_cookbooks

        #add implementation objects to hash
        implementation_hash = hash["library"][library]["implementation"] ||= Hash.new
        impl_cookbooks.each do |cookbook|
          next unless file_paths = indexed_file_paths[cookbook]
          repo = cookbook
          cmp_file_assets = file_paths.inject({}) do |h,file_path_x|
            #if repo is null then want ful file path; otherwise we have repo per cookbook and
            #want to strip off leading repo
            file_path = repo ? file_path_x.gsub(Regexp.new("^#{repo}/"),"") : file_path_x
            file_name = file_path =~ Regexp.new("/([^/]+$)") ? $1 : file_name
            file_asset = {
              :type => "chef_file", 
              :display_name => file_name,
              :file_name => file_name,
              :path => file_path
            }
            file_asset_ref = file_path.gsub(Regexp.new("/"),"_") #removing "/" since they confuse processing
            h.merge(file_asset_ref => file_asset)
          end
          implementation_hash[cookbook] = {
            "type" => "chef_cookbook",
            "version" => version,
            "repo" => repo,
            "file_asset" => cmp_file_assets
          }
        end

        #add foreign key to components that reference an implementation
        components_hash.each do |cmp_ref, cmp_info|
          cookbook = cookbook_from_component_ref(cmp_ref)
          next unless impl_cookbooks.include?(cookbook)
          cmp_info["*implementation_id"] = "/library/#{library}/implementation/#{cookbook}"
        end
      end
      def self.cookbook_from_component_ref(cmp_ref)
        cmp_ref.gsub(/__.+$/,"")
      end
    end
  end
end

