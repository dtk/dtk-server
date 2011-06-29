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
    #assumption is that target_id_handle is in uri form
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
      input_hash_content_into_model(target_id_handle,hash_content,opts)
    end

    def input_hash_content_into_model(target_id_handle,hash_content,opts={})
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

    def input_hash_content_into_model(target_id_handle,hash_content,opts={})
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
          repo = (file =~ Regexp.new("([^/]+)/[^/]+$") && $1)
          component_hash.each do |k,v|
            hash["library"][library_ref]["component"][k] = v.merge("repo" => repo)
          end
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
        Dir.chdir(base_dir) do
          pattern = impl_name ? "#{impl_name}/**/*" : "**/*"
          file_paths = Dir[pattern].select{|item|File.file?(item)}
        end
        return if file_paths.empty?

        indexed_file_paths = Hash.new
        file_paths.each do |file_path|
          dir = file_path =~ Regexp.new("(^[^/]+)/") ? $1 : nil
          (indexed_file_paths[dir] ||= Array.new) << file_path
        end
        impl_repos = indexed_file_paths.keys
        return unless impl_repos

        #add implementation objects to hash
        implementation_hash = hash["library"][library_ref]["implementation"] ||= Hash.new
        impl_repos.each do |repo|
          next unless file_paths = indexed_file_paths[repo]
          
          type = 
            case file_paths.find{|fn|fn =~ Regexp.new("r8meta\.[^/]+$")}
            when /r8meta.chef/ then ImportChefType.new()
            when /r8meta.puppet/ then ImportPuppetType.new()
          end
          next unless type

          cmp_file_assets = file_paths.inject({}) do |h,file_path_x|
            #if repo is null then want ful file path; otherwise we have repo per repo and
            #want to strip off leading repo
            file_path = repo ? file_path_x.gsub(Regexp.new("^#{repo}/"),"") : file_path_x
            file_name = file_path =~ Regexp.new("/([^/]+$)") ? $1 : file_path
            file_asset = {
              :type => type[:file_type],
              :display_name => file_name,
              :file_name => file_name,
              :path => file_path
            }
            file_asset_ref = file_path.gsub(Regexp.new("/"),"_") #removing "/" since they confuse processing
            h.merge(file_asset_ref => file_asset)
          end
          #TDOO: simple way of getting implementation
          impl_name = repo.gsub(/^puppet[-_]/,"").gsub(/^chef[-_]/,"")
          implementation_hash[repo] = {
            "display_name" => impl_name,
            "type" => type[:implementation_type],
            "version" => version,
            "repo" => repo,
            "file_asset" => cmp_file_assets
          }
        end

        #add foreign key to components that reference an implementation
        components_hash = hash["library"][library_ref]["component"]
        components_hash.each do |cmp_ref, cmp_info|
          repo = cmp_info["repo"]
          next unless repo
          cmp_info["*implementation_id"] = "/library/#{library_ref}/implementation/#{repo}"
        end
      end
      class ImportChefType < HashObject
        def initialize()
          super(:file_type => "chef_file", :implementation_type => "chef_cookbook")
        end
      end
      class ImportPuppetType < HashObject
        def initialize()
          super(:file_type => "puppet_file", :implementation_type => "puppet_module")
        end
      end
    end
  end
end

