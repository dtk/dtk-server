module DTK
  class ModuleRepoInfo < Hash
    def initialize(repo,module_name,module_idh,branch_obj,version=nil)
      super()
      repo.update_object!(:repo_name,:id)
      repo_name = repo[:repo_name]
      hash = {
        :repo_id => repo[:id],
        :repo_name => repo_name,
        :module_id => module_idh.get_id(),
        :module_name => module_name,
        :module_branch_idh => branch_obj.id_handle(),
        :repo_url => RepoManager.repo_url(repo_name),
        :workspace_branch => branch_obj.get_field?(:branch),
        :branch_head_sha => RepoManager.branch_head_sha(branch_obj)
      }
      if version
        hash.merge!(:version => version)
        if assembly_name = version.respond_to?(:assembly_name) && version.assembly_name()
          hash.merge!(:assembly_name => assembly_name)
        end
      end
      replace(hash)
    end
  end

  class CloneUpdateInfo < ModuleRepoInfo
    def initialize(module_obj,version=nil)
      aug_branch = module_obj.get_augmented_workspace_branch(:filter => {:version => version})
      super(aug_branch[:repo],aug_branch[:module_name],module_obj.id_handle(),aug_branch,version)
      replace(Aux.hash_subset(self,[:repo_name,:repo_url,:module_name,:workspace_branch]))
      self[:commit_sha] = aug_branch[:current_sha]
    end
  end

  r8_nested_require('mixins','remote')  
  
  module ModuleMixin
    include ModuleRemoteMixin

    def get_module_branches()
      get_objs_helper(:module_branches,:module_branch)
    end

    def get_module_branch_matching_version(version=nil)
      get_module_branches().find{|mb|mb.matches_version?(version)}
    end

    def get_workspace_branch_info(version=nil,opts={})
      if aug_branch = get_augmented_workspace_branch({:filter => {:version => version}}.merge(opts))
        module_name = aug_branch[:module_name]
        ModuleRepoInfo.new(aug_branch[:repo],module_name,id_handle(),aug_branch,version)
      end
    end

    def ret_clone_update_info(version=nil)
      CloneUpdateInfo.new(self,version)
    end

    ##
    # Returns local and remote versions for module
    #
    def local_and_remote_versions(client_rsa_pub_key = nil, opts={})
      module_name, remote_versions = nil, []

      # get local versions list and remove master(nil) from list
      local_versions = self.class.versions(get_objs(:cols => [:version_info])).map!{|v| v.nil? ? "CURRENT" : v}
      
      # get all remote modules versions, and take only versions for current component module name
      info = self.class.info(model_handle(), id(), opts)
      module_name = info[:remote_repos].first[:repo_name].gsub(/\*/,'').strip() unless info[:remote_repos].empty?
      remote_versions = self.class.list_remotes(model_handle, client_rsa_pub_key).select{|r|r[:display_name]==module_name}.collect{|v_remote| ModuleBranch.version_from_version_field(v_remote[:versions])}.map!{|v| v.nil? ? "CURRENT" : v} if module_name
      
      local_hash  = {:namespace => "local", :versions => local_versions.flatten}
      remote_hash = {:namespace => "remote", :versions => remote_versions}

      versions = [local_hash]
      versions << remote_hash unless remote_versions.empty?

      versions
    end

    def get_augmented_workspace_branch(opts={})
      version = (opts[:filter]||{})[:version]
      version_field = ModuleBranch.version_field(version) #version can be nil

      sp_hash = {
        :cols => [:display_name,:workspace_info_full]
      }
      module_rows = get_objs(sp_hash).select{|r|r[:module_branch][:version] == version_field}
      if module_rows.size == 0
        unless opts[:donot_raise_error]
          raise ErrorUsage.new("Module #{pp_module_name(version)} does not exist")
        end
        return nil
      end

      #aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
      unless module_obj = aggregate_by_remote_namespace(module_rows,opts)
        raise ErrorUsage.new("There is no module (#{pp_module_name(version)}) with namespace '#{opts[:filter][:remote_namespace]}'")
      end
      module_obj[:module_branch].merge(:repo => module_obj[:repo],:module_name => module_obj[:display_name])
    end

    #type is :library or :workspace
    def find_branch(type,branches)
      matches =
        case type
          when :library then branches.reject{|r|r[:is_workspace]} 
          when :workspace then branches.select{|r|r[:is_workspace]} 
          else raise Error.new("Unexpected type (#{type})")
        end
      if matches.size > 1
        Error.new("Unexpected that there is more than one matching #{type} branches")
      end
      matches.first
    end

    def create_new_version(new_version,opts={},client_rsa_pub_key=nil)
      opts_get_aug = Opts.new
      if base_version = opts[:base_version]
        opts_get_aug.merge(:filter => {:version => base_version})
      end
      unless aug_ws_branch = get_augmented_workspace_branch(opts_get_aug)
        raise ErrorUsage.new("There is no module (#{pp_module_name()}) in the workspace")
      end

      #make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        raise ErrorUsage.new("Version exists already for module (#{pp_module_name(new_version)})")
      end
      repo_for_new_version = aug_ws_branch.create_new_branch_from_this_branch?(get_project(),aug_ws_branch[:repo],new_version)
      opts_type_spec = opts.merge(:ancestor_branch_idh => aug_ws_branch.id_handle())
      ret = create_new_version__type_specific(repo_for_new_version,new_version,opts_type_spec)
      opts[:ret_module_branch] = opts_type_spec[:ret_module_branch] if  opts_type_spec[:ret_module_branch]
      ret
    end

    def update_model_from_clone_changes?(commit_sha,diffs_summary,version,opts={})
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)
      parse_needed = !dsl_parsed?()
      return unless pull_was_needed or parse_needed

      opts_update = Hash.new
      opts_update.merge!(:do_not_raise => true) if opts[:internal_trigger]
      opts_update.merge!(:modification_type => opts[:modification_type]) if opts[:modification_type] 
      response = update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts_update)
      
      if (response.is_a?(ErrorUsage::DSLParsing) || response.is_a?(ErrorUsage::DanglingComponentRefs))
        {:dsl_parsed_info => response}
      else
        response
      end
    end

    def get_project()
      #caching
      return self[:project] if self[:project]
      update_object!(:project_project_id,:display_name) #including :display_name is opportunistic
      if project_id = self[:project_project_id]
        self[:project] = id_handle(:model_name => :project, :id => project_id).create_object()
      end
    end

     # raises exception if more repos found
    def get_repo!()
      repos = get_repos()
     
      unless repos.size == 1
        raise Error.new("unexpected that number of matching repos is not equal to 1")
      end
      
      return repos.first()
    end

    def get_repos()
      get_objs_uniq(:repos)
    end

    def get_workspace_repo()
      sp_hash = {
        :cols => [:id,:display_name,:workspace_info,:project_project_id]
      }
      row = get_obj(sp_hash)
      #opportunistically set display name and project_project_id on module
      self[:display_name] ||= row[:display_name]
      self[:project_project_id] ||= row[:project_project_id]
      row[:repo]
    end
    #MOD_RESTRUCT: deprecate below for above
    def get_library_repo()
      sp_hash = {
        :cols => [:id,:display_name,:library_repo,:library_library_id]
      }
      row = get_obj(sp_hash)
      #opportunistically set display name and library_library_id on module
      self[:display_name] ||= row[:display_name]
      self[:library_library_id] ||= row[:library_library_id]
      row[:repo]
    end

    def get_implementations()
      get_objs_uniq(:implementations)
    end
    def get_library_implementations()
      get_objs_uniq(:library_implementations)
    end
    def module_type()
      self.class.module_type()
    end

    def get_workspace_module_branch(version=nil)
      mb_mh = model_handle().create_childMH(:module_branch)
      sp_hash = {
        :cols => ModuleBranch.common_columns(),
        :filter => [:and,[:eq,mb_mh.parent_id_field_name(),id()],
                    [:eq,:is_workspace,true],
                    [:eq,:version,ModuleBranch.version_field(version)]]
      }
      Model.get_obj(mb_mh,sp_hash)
    end

    #MOD_RESTRUCT: may replace below with above
    def get_module_branch(branch)
      sp_hash = {
        :cols => [:module_branches]
      }
      module_branches = get_objs(sp_hash).map{|r|r[:module_branch]}
      module_branches.find{|mb|mb[:branch] == branch}
    end

    def module_name()
      get_field?(:display_name)
    end

    def pp_module_name(version=nil)
      self.class.pp_module_name(module_name(),version)
    end

    def pp_module_branch_name(module_branch)
      module_branch.update_object!(:version)
      version = (module_branch.has_default_version?() ? nil : module_branch[:version])
      self.class.pp_module_name(module_name(),version)
    end

    def set_dsl_parsed!(boolean_val)
      update(:dsl_parsed => boolean_val)
    end

    def dsl_parsed?()
      get_field?(:dsl_parsed)
    end

    #assumed that all raw_module_rows agree on all except repo_remote
    def aggregate_by_remote_namespace(raw_module_rows,opts={})
      ret = nil
      #raw_module_rows should have morea than 1 row and should agree on all fields aside from :repo_remote
      if raw_module_rows.empty?()
        raise Error.new("Unexepected that raw_module_rows is empty")
      end
      namespace = (opts[:filter]||{})[:remote_namespace]

      repo_remotes = raw_module_rows.map do |e|
        repo_remote = e.delete(:repo_remote)
        if namespace.nil? or namespace == repo_remote[:repo_namespace]
          repo_remote
        end
      end.compact
      #if filtering by namespace (tested by namespace is non-null) and nothing matched then return ret (which is nil)
      if namespace and repo_remotes.empty?
        return ret
      end

      ret = raw_module_rows.first.merge(:repo_remotes => repo_remotes)
      repo = ret[:repo]
      if default = RepoRemote.ret_default_remote_repo(ret[:repo_remotes])
        repo.consume_remote_repo!(default)
      end
      ret
    end

   private
    def library_branch_name(version=nil)
      library_id = update_object!(:library_library_id)[:library_library_id]
      library_idh = id_handle(:model_name => :library, :id => library_id)
      ModuleBranch.library_branch_name(library_idh,version)
    end
  end

  module ModuleClassMixin
    include ModuleRemoteClassMixin
    def component_type()
      case module_type()
       when :service_module
        :service_module
       when :component_module
        :puppet #TODO: hard wired
      end
    end

    def module_type()
      model_name()
    end

    def check_valid_id(model_handle,id)
      check_valid_id_default(model_handle,id)
    end
    def name_to_id(model_handle,name)
      name_to_id_default(model_handle,name)
    end

    #
    # returns Array with: name, namespace, version
    #
    def get_basic_info(target_mh, id, opts={})
      sp_hash = {
        :cols => [:id, :display_name, :version, :remote_repos],
        :filter => [:eq,:id, id.to_i]
      }

      response = get_obj(target_mh, sp_hash.merge(opts))

      # return name, namespace and version
      return response[:display_name], (response[:repo_remote]||{})[:repo_namespace], response[:module_branch][:version] 
    end

    def info(target_mh, id, opts={})
      remote_repo_cols = [:id, :display_name, :version, :remote_repos, :dsl_parsed]
      components_cols  = [:id, :display_name, :version, :dsl_parsed]
      project_idh      = opts[:project_idh]
      namespaces = []

      sp_hash = {
        :cols => remote_repo_cols,
        :filter => [:eq,:id,id]
      }

      response = get_objs(target_mh, sp_hash.merge(opts))

      # if there are no remotes just get component info
      if response.empty?
        sp_hash[:cols] = components_cols
        response = get_objs(target_mh, sp_hash.merge(opts))
      else
        # we sort in ascending order, last remote is default one
        #TODO: need to make more sophisticated so we dont end up comparing a '' to a date
        response.sort { |a,b| ((b[:repo_remote]||{})[:created_at]||'') <=> ((a[:repo_remote]||{})[:created_at]||'')}

        # we switch to ascending order
        response.each_with_index do |e,i|
          display_name = (e[:repo_remote]||{})[:display_name]
          prefix = ( i == 0 ? "*" : " ")
          namespaces << { :repo_name => "#{prefix} #{display_name}" }
        end
      end

      filter_list!(response) if respond_to?(:filter_list!)
      response.each{|r|r.merge!(:type => r.component_type()) if r.respond_to?(:component_type)}
      mh = project_idh.createMH(model_type())
      response = ListMethodHelpers.aggregate_detail(response,mh,Opts.new(:include_versions => true))

      ret = response.first || {}
      ret[:versions] = "CURRENT" unless ret[:versions]
      ret.delete_if { |k,v| [:repo,:module_branch,:repo_remote].include?(k) }
      # [Haris] Due to join condition with module.branch we can have situations where we have many versions 
      # of module with same remote branch, with 'uniq' we iron that out

      ret.merge!(:remote_repos => namespaces.uniq ) if namespaces
      ret
    end


    def list(opts=opts.new)
      diff               = opts[:diff]
      project_idh        = opts.required(:project_idh)
      remote_rep         = opts[:remote_rep]
      include_remotes    = opts.array(:detail_to_include).include?(:remotes)
      include_versions   = opts.array(:detail_to_include).include?(:versions)
      include_any_detail = ((include_remotes or include_versions) ? true : nil)

      cols = [:id, :display_name, :dsl_parsed, include_any_detail && :module_branches_with_repos].compact
      unsorted_ret = get_all(project_idh,cols)
      filter_list!(unsorted_ret) if respond_to?(:filter_list!)
      unsorted_ret.each{|r|r.merge!(:type => r.component_type()) if r.respond_to?(:component_type)}
      if include_any_detail
        mh = project_idh.createMH(model_type())
        unsorted_ret = ListMethodHelpers.aggregate_detail(unsorted_ret,mh,Opts.new(:include_remotes => include_remotes,:include_versions => include_versions, :remote_rep => remote_rep, :diff => diff))
      end
      unsorted_ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def get_all(project_idh,cols=nil)
      sp_hash = {
        :cols => cols || [:id,:group_id,:isplay_name],
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      mh = project_idh.createMH(model_type())
      get_objs(mh,sp_hash)
    end

    #argument can be array or single element (hash)
    def versions(modules_with_branches)
      modules_with_branches = [modules_with_branches] unless modules_with_branches.kind_of?(Array)
      modules_with_branches.collect{|r| ModuleBranch.version_from_version_field(r[:module_branch][:version])}
    end

    module ListMethodHelpers
      def self.aggregate_detail(branch_module_rows,module_mh,opts)
        diff       = opts[:diff]
        remote_rep = opts[:remote_rep]

        if opts[:include_remotes]
          augment_with_remotes_info!(branch_module_rows,module_mh)
        end
        
        #there can be dupliactes for a module when multiple repos; in which case will agree on all fields
        #except :repo, :module_branch, and :repo_remotes
        #index by module
        ndx_ret = Hash.new
        #aggregate
        branch_module_rows.each do |r|
          module_branch = r[:module_branch]
          ndx_repo_remotes = r[:ndx_repo_remotes]
          ndx = r[:id]
          is_equal = nil
          
          if diff
            repo = r[:repo]
            linked_remote = repo.linked_remote?(remote_rep)
            is_equal = repo.ret_loaded_and_remote_diffs(remote_rep, module_branch) if linked_remote
          end
                    
          repo_remotes_added = false
          unless mdl = ndx_ret[ndx]
            r.delete(:repo)
            r.delete(:module_branch)
            mdl = ndx_ret[ndx] = r
          end
          mdl.merge!(:is_equal => is_equal)

          if opts[:include_versions]
            (mdl[:version_array] ||= Array.new) << module_branch.version_print_form(Opts.new(:default_version_string => DefaultVersionString))
          end

          if ndx_repo_remotes and not repo_remotes_added
            ndx_repo_remotes.each do |remote_repo_id,remote_repo|
              (mdl[:ndx_repo_remotes] ||= Hash.new)[remote_repo_id] ||= remote_repo
            end
          end
        end
        #put in display name form
        ndx_ret.each_value do |mdl|
          if raw_va = mdl.delete(:version_array)
            unless raw_va.size == 1 and raw_va.first == DefaultVersionString
              version_array = (raw_va.include?(DefaultVersionString) ? [DefaultVersionString] : []) + raw_va.reject{|v|v == DefaultVersionString}.sort
              mdl.merge!(:versions => version_array.join(", ")) 
            end
          end

          if ndx_repo_remotes = mdl.delete(:ndx_repo_remotes)
            mdl.merge!(:linked_remotes => ret_linked_remotes_print_form(ndx_repo_remotes.values))
          end
        end

        ndx_ret.values
      end
      DefaultVersionString = "CURRENT"

     private 

      def self.augment_with_remotes_info!(branch_module_rows,module_mh)
        #index by repo_id
        ndx_branch_module_rows = branch_module_rows.inject(Hash.new){|h,r|h.merge(r[:repo][:id] => r)}
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:repo_id,:created_at,:is_default],
          :filter => [:oneof, :repo_id, ndx_branch_module_rows.keys]
        }
        Model.get_objs(module_mh.createMH(:repo_remote),sp_hash).each do |r|
          ndx = r[:repo_id]
          (ndx_branch_module_rows[ndx][:ndx_repo_remotes] ||= Hash.new).merge!(r[:id] => r)
        end
        branch_module_rows
      end

      def self.ret_linked_remotes_print_form(repo_remotes)
        if repo_remotes.size == 1
          repo_remotes.first.print_form()
        else
          default = RepoRemote.ret_default_remote_repo(repo_remotes)
          repo_remotes.reject!{|r|r[:id] == default[:id]}
          sorted_array = [default.print_form(Opts.new(:is_default_namespace => true))] + repo_remotes.map{|r|r.print_form()}
          sorted_array.join(", ")
        end
      end
    end

    def add_user_direct_access(model_handle,rsa_pub_key,username=nil)
      repo_user,match = RepoUser.add_repo_user?(:client,model_handle.createMH(:repo_user),{:public => rsa_pub_key},username)
      model_name = model_handle[:model_name]

      repo_user.update_direct_access(model_name,true)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.set_user_rights_in_repos(repo_user[:username],repo_names,DefaultAccessRights)

        repos.map{|repo|RepoUserAcl.update_model(repo,repo_user,DefaultAccessRights)}
      end
      return match, repo_user[:username]
    end

    DefaultAccessRights = "RW+"

    def remove_user_direct_access(model_handle,username)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user),:username => username)
      return unless repo_user

      model_name = model_handle[:model_name]
      return unless repo_user.has_direct_access?(model_name)

      RepoManager.delete_user(username)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.remove_user_rights_in_repos(username,repo_names)
        #repo user acls deleted by foriegn key cascade
      end

      if repo_user.any_direct_access_except?(model_name)
        repo_user.update_direct_access(model_name,false)
      else
        delete_instance(repo_user.id_handle())
      end
    end

    #returns hash with keys :module_idh :module_branch_idh
    def create_module(project,module_name,config_agent_type,version=nil,opts={})
      is_parsed   = false
      project_idh = project.id_handle()
      module_exists = module_exists?(project_idh,module_name)
      if module_exists
        is_parsed = module_exists[:dsl_parsed] 
      end

      if is_parsed and not opts[:no_error_if_exists]
        raise ErrorUsage.new("Module (#{module_name}) cannot be created since it exists already")
      end
      ws_branch = ModuleBranch.workspace_branch_name(project,version)
      create_opts = {
        :create_branch => ws_branch,
        :push_created_branch => true,
        :donot_create_master_branch => true,
        :delete_if_exists => true
      }
      repo = create_empty_workspace_repo(project_idh,module_name,module_specific_type(config_agent_type),create_opts)
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_and_branch_info.merge(:module_repo_info => module_repo_info(repo,module_and_branch_info,version))
    end

    def module_repo_info(repo,module_and_branch_info,version)
      info = module_and_branch_info #for succinctness
      branch_obj = info[:module_branch_idh].create_object()
      ModuleRepoInfo.new(repo,info[:module_name],info[:module_idh],branch_obj,version)
    end

    #can be overwritten
    def module_specific_type(config_agent_type)
      module_type()
    end
    private :module_specific_type

    def create_empty_workspace_repo(project_idh,module_name,module_specific_type,opts={})
      auth_repo_users = RepoUser.authorized_users(project_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end

      Repo.create_empty_workspace_repo(project_idh,module_name,module_specific_type,repo_user_acls,opts)
    end

    def get_workspace_module_branch(project,module_name,version=nil,opts={})
      project_idh = project.id_handle()
      filter = [:and, [:eq, :display_name, module_name], [:eq, :project_project_id, project_idh.get_id()]]
      branch = ModuleBranch.workspace_branch_name(project,version)
      post_filter = proc{|mb|mb[:branch] == branch}
      matches = get_matching_module_branches(project_idh,filter,post_filter,opts)
      if matches.size == 0
        nil
      elsif matches.size == 1
        matches.first
      elsif matches.size > 2
        raise Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
      end
    end

    def get_matching_module_branches(mh_or_idh,filter,post_filter=nil,opts={})
      sp_hash = {
        :cols => [:id,:display_name,:group_id,:module_branches],
        :filter => filter
      }
      rows = get_objs(mh_or_idh.create_childMH(module_type()),sp_hash).map do |r|
        r[:module_branch].merge(:module_id => r[:id])
      end
      if rows.empty?
        return Array.new if opts[:no_error_if_does_not_exist]
        raise ErrorUsage.new("Module does not exist")
      end
      post_filter ? rows.select{|r|post_filter.call(r)} : rows
    end

    def pp_module_name(module_name,version=nil)
      version ? "#{module_name} (#{version})" : module_name
    end

    def create_ws_module_and_branch_obj?(project,repo_idh,module_name,input_version,ancestor_branch_idh=nil)
      project_idh = project.id_handle()
      ref = module_name
      module_type = model_name.to_s
      opts = {:version => input_version}
      opts.merge!(:ancestor_branch_idh => ancestor_branch_idh) if ancestor_branch_idh
      mb_create_hash = ModuleBranch.ret_workspace_create_hash(project,module_type,repo_idh,opts)
      version = mb_create_hash.values.first[:version]

      fields = {
        :display_name => module_name,
        :module_branch => mb_create_hash
      }

      create_hash = {
        model_name.to_s => {
          ref => fields
        }
      }
      input_hash_content_into_model(project_idh,create_hash)

      module_branch = get_workspace_module_branch(project,module_name,version)
      module_idh =  project_idh.createIDH(:model_name => model_name(),:id => module_branch[:module_id])
      {:version => version, :module_name => module_name, :module_idh => module_idh,:module_branch_idh => module_branch.id_handle()}
    end

    def module_exists?(project_idh,module_name)
      unless project_idh[:model_name] == :project
        raise Error.new("MOD_RESTRUCT:  module_exists? should take a project, not a (#{project_idh[:model_name]})")
      end
      sp_hash = {
        :cols => [:id, :display_name, :dsl_parsed],
        :filter => [:and, [:eq, :project_project_id, project_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      get_obj(project_idh.createMH(model_name()),sp_hash)
    end

   private
    def get_all_repos(mh)
      get_objs(mh,{:cols => [:repos]}).inject(Hash.new) do |h,r|
        repo = r[:repo]
        h[repo[:id]] ||= repo
        h
      end.values
    end

  end
end
