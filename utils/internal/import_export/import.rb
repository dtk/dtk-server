#TODO: unify with file_asset/r8_meta
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
    #assumption is that top_container_idh is in uri form
    #returns [library_idh,implementation_idh]
    def create_file_assets_from_dir_els(top_container_idh,module_dir,module_name,config_agent_type)
      library_impl_hash = Implementation::ret_library_implementation_hash(module_dir,module_name,config_agent_type)
      username = CurrentSession.get_user_username()
      users_private_lib_name = "private-#{username}"
      hash_content = {
        "library" => {
          users_private_lib_name => {
            "display_name" => users_private_lib_name,
            "implementation" => library_impl_hash
          }
        } 
      }
      input_hash_content_into_model(top_container_idh,hash_content)
      library_ref = users_private_lib_name
      #assumption is that library_impl_hash only has one impleemntation in it
      impl_ref = library_impl_hash.keys.first
      ret_library_and_impl_id_handles(top_container_idh,library_ref,impl_ref)
    end

    #TODO: this is somewhat of a hack; better is if input_hash_content_into_model gave this info
    def ret_library_and_impl_id_handles(top_container_idh,library_ref,impl_ref)
      library_uri = "/library/#{library_ref}"
      impl_uri = "#{library_uri}/implementation/#{impl_ref}"
      [[:library,library_uri],[:implementation,impl_uri]].map do |mn,uri|
        top_container_idh.createIDH(:model_name => mn, :uri => uri)
      end
    end

    #TODO: make this version dependent
    def add_library_components_from_r8meta(config_agent_type,library_idh,impl_idh,r8meta_hash)
      impl_id = impl_idh.get_id()
      remote_link_defs = Hash.new
      cmps_hash = r8meta_hash.inject({}) do |h, (r8_hash_cmp_ref,cmp_info)|
        info = Hash.new
        cmp_info.each do |k,v|
          case k
           when "external_link_defs"
            v.each{|ld|(ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}} #TODO: temp hack to put in type = "external"
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
           when "link_defs" 
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          else
            info[k] = v
          end
        end
        info.merge!("implementation_id" => impl_id)
        cmp_ref = component_ref(config_agent_type,r8_hash_cmp_ref)
        h.merge(cmp_ref => info)
      end
      #process the link defs for remote components
      process_remote_link_defs!(cmps_hash,remote_link_defs,library_idh)
      input_hash_content_into_model(library_idh,{"component" => cmps_hash})
      sp_hash =  {
        :cols => [:id,:display_name], 
        :filter => [:and,[:oneof,:ref,cmps_hash.keys],[:eq,:library_library_id,library_idh.get_id()]]
      }
      component_idhs = get_objs(library_idh.create_childMH(:component),sp_hash).map{|r|r.id_handle()}
      component_idhs
    end

    #### private helpers
    def component_ref(config_agent_type,r8_hash_cmp_ref)
      #TODO: may be better to have these prefixes already in r8 meta file
      "#{config_agent_type}-#{r8_hash_cmp_ref}"
    end
    def component_ref_from_cmp_type(config_agent_type,component_type)
      "#{config_agent_type}-#{component_type}"
    end

    #updates both cmps_hash and remote_link_defs
    def process_remote_link_defs!(cmps_hash,remote_link_defs,library_idh)
      return if remote_link_defs.empty?
      #process all remote_link_defs in this module
      remote_link_defs.each do |remote_cmp_type,remote_link_def|
        config_agent_type = remote_link_def.values.first[:config_agent_type]
        remote_cmp_ref = component_ref_from_cmp_type(config_agent_type,remote_cmp_type)
        if cmp_pointer = cmps_hash[remote_cmp_ref]
          (cmp_pointer["link_def"] ||= Hash.new).merge!(remote_link_def)
          remote_link_defs.delete(remote_cmp_type)
        end
      end

      #process remaining remote_link_defs to see if in stored modules
      return if remote_link_defs.empty?
      sp_hash = {
        :cols => [:id,:ref,:component_type],
        :filter => [:oneof,:component_type,remote_link_defs.keys]
      }
      stored_remote_cmps = library_idh.create_object().get_children_objs(:component,sp_hash,:keep_ref_cols=>true)
      ndx_stored_remote_cmps = stored_remote_cmps.inject({}){|h,cmp|h.merge(cmp[:component_type] => cmp)}
      remote_link_defs.each do |remote_cmp_type,remote_link_def|
        if remote_cmp = ndx_stored_remote_cmps[remote_cmp_type]
          remote_cmp_ref = remote_cmp[:ref]
          cmp_pointer = cmps_hash[remote_cmp_ref] ||= {"link_def" => Hash.new}
          cmp_pointer["link_def"].merge!(remote_link_def)
          remote_link_defs.delete(remote_cmp_type)
        end
      end

      #if any remote_link_defs left they are dangling refs
      remote_link_defs.keys.each do |remote_cmp_type|
        Log.error("link def references a remote component (#{remote_cmp_type}) that does not exist")
      end
    end
    private :component_ref, :component_ref_from_cmp_type, :process_remote_link_defs!
    #### end: privaate helpers

    #assumption is that target_id_handle is in uri form
    def import_objects_from_file(target_id_handle,json_file,opts={})
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      hash_content = Aux::hash_from_file_with_json(json_file) 
      import_objects_from_hash(target_id_handle,hash_content,opts)
    end

    #assumption is that target_id_handle is in uri form
    def import_objects_from_hash(target_id_handle,hash_content,opts={})
      create_prefix_object_if_needed(target_id_handle,opts)
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
        global_fks = input_into_model(target_id_handle,hash_content,opts) 
      else
        hash_content.each do |relation_type,info|
          info.each do |ref,child_hash_content|
            child_uri = uri_qualified_by_username(relation_type,ref,opts[:username])
            child_target_id_handle = target_id_handle.createIDH(:uri => child_uri)
            create_prefix_object_if_needed(child_target_id_handle,opts)
            input_opts = {:ret_global_fks => true}.merge(opts.reject{|k,v| not [:username,:preserve_input_hash].include?(k)})
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
      format_type = r8meta[:type]
      if format_type == :yaml
        library_ref = r8meta[:library]
        require 'yaml'
        remote_link_defs = Hash.new
        r8meta[:files].each do |file|
          component_hash = YAML.load_file(file)
          repo, config_agent_type = (file =~ Regexp.new("([^/]+)/r8meta\.(.+)\.yml") && [$1,$2])
          raise Error.new("bad config agent type") unless config_agent_type
          component_hash.each do |local_cmp_type,v|
            cmp_ref = "#{config_agent_type}-#{local_cmp_type}"
            #TODO: right now; links defs just have internal
            if link_defs = v.delete("link_defs")
              parsed_link_def = LinkDef.parse_serialized_form_local(link_defs,config_agent_type,remote_link_defs)
              (v["link_def"] ||= Hash.new).merge!(parsed_link_def)
            end
            #TODO: when link_defs have externa;l deprecate below
            if ext_link_defs = v.delete("external_link_defs")
              #TODO: temp hack to put in type = "external"
              ext_link_defs.each do |ld|
                (ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}
              end
              parsed_link_def = LinkDef.parse_serialized_form_local(ext_link_defs,config_agent_type,remote_link_defs)
              (v["link_def"] ||= Hash.new).merge!(parsed_link_def)
              #TODO: deprecate below
              v["link_defs"] ||= Hash.new
              v["link_defs"]["external"] = ext_link_defs
            end
            hash["library"][library_ref]["component"][cmp_ref] = v.merge("repo" => repo)
          end
        end
        #process the link defs for remote components
        remote_link_defs.each do |remote_cmp_type,remote_link_def|
          config_agent_type = remote_link_def.values.first.delete(:config_agent_type)
          remote_cmp_ref = "#{config_agent_type}-#{remote_cmp_type}"
          cmp_pointer = hash["library"][library_ref]["component"][remote_cmp_ref]
          if cmp_pointer
            (cmp_pointer["link_def"] ||= Hash.new).merge!(remote_link_def)
          else
            Log.error("link def references a remote component (#{remote_cmp_ref}) that does not exist")
          end
        end 
      else
        raise Error.new("Format type #{format_type} not supported")
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
        components_hash.each_value do |cmp_info|
          next unless repo = cmp_info["repo"]
          cmp_info["*implementation_id"] = "/library/#{library_ref}/implementation/#{repo}"
        end
      end

      #TODO: deprecate
      def self.ret_library_implementation_hash(module_dir,module_name,config_agent_type)
        file_paths = Array.new
        Dir.chdir(module_dir) do
          pattern = "**/*"
          file_paths = Dir[pattern].select{|item|File.file?(item)}
        end

        file_type = "#{config_agent_type}_file"
        file_assets = file_paths.inject({}) do |h,file_path|
          file_name = file_path =~ Regexp.new("/([^/]+$)") ? $1 : file_path
          file_asset = {
            :type => file_type,
            :display_name => file_name,
            :file_name => file_name,
            :path => file_path
          }
          file_asset_ref = file_path.gsub(Regexp.new("/"),"_") #removing "/" since they confuse processing
          h.merge(file_asset_ref => file_asset)
        end
        repo = module_dir.split("/").last
        {repo => {
            "display_name" => repo,
            "parse_state" => "unparsed",
            "module_name" => module_name,
            "type" => config_agent_type.to_s,
            "repo" => repo,
            "file_asset" => file_assets
          }
        }
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

