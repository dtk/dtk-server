module XYZ
  module CommonInputImport
    def uri_qualified_by_username(relation_type,ref,username)
      username ? "/#{relation_type}/#{ref}-#{username}" : "/#{relation_type}/#{ref}"
    end
    def modify_uri_with_user_name(uri,username)
      return uri unless username
      if uri =~ Regexp.new("^(/[^/]+/[^/]+)(/.+$)") 
        "#{$1}-#{username}#{$2}" 
      elsif uri =~ Regexp.new("^/[^/]+/[^/]+$")
        "#{uri}-#{username}"
      else
        uri
      end
    end
  end

  #class mixin
  module ImportObject
    include CommonInputImport
    #not idempotent
    #TBD: assumption is that target_id_handle is in uri form
    def import_objects_from_file(target_id_handle,json_file,opts={})
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      create_prefix_object_if_needed(target_id_handle,opts)
      hash_content = Aux::hash_from_file_with_json(json_file) 
      return nil unless hash_content
      type_info = Hash.new
      add_r8meta!(hash_content,opts[:r8meta]) if opts[:r8meta]
      if opts[:add_implementations]
        impl_info = opts[:add_implementations]
        library_ref = impl_info[:library]
        base_dir = impl_info[:base_directory]
        version = impl_info[:version]
        add_implementations!(hash_content,version,library_ref,base_dir)
      end
      global_fks = Hash.new
      unless target_id_handle.is_top?
        #TODO: do we need to factor in opts[:username] here?
        global_fks = input_into_model(target_id_handle,hash_content) 
      else
        hash_content.each do |relation_type,info|
          info.each do |ref,child_hash_content|
            child_uri = uri_qualified_by_username(relation_type,ref,opts[:username])
            child_target_id_handle = target_id_handle.createIDH(:uri => child_uri)
            create_prefix_object_if_needed(child_target_id_handle,opts)
            input_opts = {:ret_global_fks => true}.merge(opts.reject{|k,v| not k == :username})
            r = input_into_model(child_target_id_handle,child_hash_content,input_opts)
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
      create_simple_instance?(target_id_handle)
    end

    def add_r8meta!(hash,r8meta)
      type = r8meta[:type]
      if type == :yaml
        library_ref = r8meta[:library]
        require 'yaml'
        r8meta[:files].each do |file|
          component_hash = YAML.load_file(file)
          component_hash.each{|k,v|hash["library"][library_ref]["component"][k] = v}
        end 
      else
        raise Error.new("Type #{type} not supported")
      end
    end

    def add_implementations!(hash,version,library_ref,base_dir,impl_name=nil)
      Implementation::add_implementations!(hash,version,library_ref,base_dir,impl_name)
    end

    module Implementation
      def self.add_implementations!(hash,version,library_ref,base_dir,impl_name=nil)
        file_paths = Array.new
        cur_dir = Dir.pwd
        begin
          Dir.chdir(base_dir)
          pattern = impl_name ? "#{impl_name}/**/*" : "**/*"
          file_paths = Dir[pattern].select{|item|File.file?(item)}
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
        components_hash = hash["library"][library_ref]["component"]
        impl_repos = components_hash.keys.map{|cmp_ref|repo_from_component_ref(cmp_ref)}.uniq & indexed_file_paths.keys
        return unless impl_repos

        #add implementation objects to hash
        implementation_hash = hash["library"][library_ref]["implementation"] ||= Hash.new
        impl_repos.each do |repo|
          next unless file_paths = indexed_file_paths[repo]
          type = nil
          cmp_file_assets = file_paths.inject({}) do |h,file_path_x|
            #if repo is null then want ful file path; otherwise we have repo per repo and
            #want to strip off leading repo
            file_path = repo ? file_path_x.gsub(Regexp.new("^#{repo}/"),"") : file_path_x
            file_name = file_path =~ Regexp.new("/([^/]+$)") ? $1 : file_path
            unless type 
              if file_name =~ /^r8meta.chef/ then type = "chef_cookbook"
              elsif file_name =~ /^r8meta.puppet/ then type = "puppet_module"
              end
            end
            file_asset = {
              :type => "chef_file", 
              :display_name => file_name,
              :file_name => file_name,
              :path => file_path
            }
            file_asset_ref = file_path.gsub(Regexp.new("/"),"_") #removing "/" since they confuse processing
            h.merge(file_asset_ref => file_asset)
          end
          unless type
            Log.error("cannot find valid r8meta file")
            next
          end
          implementation_hash[repo] = {
            "display_name" => repo,
            "type" => type,
            "version" => version,
            "repo" => repo,
            "file_asset" => cmp_file_assets
          }
        end

        #add foreign key to components that reference an implementation
        components_hash.each do |cmp_ref, cmp_info|
          repo = repo_from_component_ref(cmp_ref)
          next unless impl_repos.include?(repo)
          cmp_info["*implementation_id"] = "/library_ref/#{library_ref}/implementation/#{repo}"
        end
      end
      def self.repo_from_component_ref(cmp_ref)
        cmp_ref.gsub(/__.+$/,"")
      end
    end
  end
end

