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
        :workspace_branch => branch_obj.get_field?(:branch)
      }
      hash.merge!(:version => version) if version
      replace(hash)
    end
  end

  class CloneUpdateInfo < ModuleRepoInfo
    def initialize(module_obj,version=nil)
      aug_branch = module_obj.get_augmented_workspace_branch(Opts.new(:filter => {:version => version}))
      super(aug_branch[:repo],aug_branch[:module_name],module_obj.id_handle(),aug_branch,version)
      replace(Aux.hash_subset(self,[:repo_name,:repo_url,:module_name,:workspace_branch]))
      self[:commit_sha] = aug_branch[:current_sha]
    end
  end

  r8_nested_require('module_mixins','remote')  

  module ModuleMixin
    include ModuleRemoteMixin

    def get_module_branches()
      get_objs_helper(:module_branches,:module_branch)
    end

    def get_module_branch_matching_version(version=nil)
      get_module_branches().find{|mb|mb.matches_version?(version)}
    end

    def get_workspace_branch_info(version=nil)
      aug_branch = get_augmented_workspace_branch(Opts.new(:filter => {:version => version}))
      module_name = aug_branch[:module_name]
      ModuleRepoInfo.new(aug_branch[:repo],module_name,id_handle(),aug_branch,version)
    end

    def ret_clone_update_info(version=nil)
      CloneUpdateInfo.new(self,version)
    end

    def get_augmented_workspace_branch(opts=Opts.new)
      version = (opts[:filter]||{})[:version]
      version_field = ModuleBranch.version_field(version) #version can be nil

      sp_hash = {
        :cols => [:display_name,:workspace_info_full]
      }
      module_rows = get_objs(sp_hash).select{|r|r[:module_branch][:version] == version_field}
      if module_rows.size == 0
        unless opts[:donot_raise_error]
          raise ErrorUsage.new("Module (#{pp_module_name(version)}) does not exist")
        end
        return nil
      end

      #aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
      unless module_obj = aggregate_by_remote_namespace(module_rows,opts)
        raise ErrorUsage.new("There is no module (#{pp_module_name(version)}) taht meets filter conditions")
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

    def create_new_version(new_version)
      unless aug_ws_branch = get_augmented_workspace_branch()
        raise ErrorUsage.new("There is no module (#{pp_module_name()}) in the workspace")
      end

      #make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        raise ErrorUsage.new("Version exists already for module (#{pp_module_name(new_version)})")
      end
      #TODO: may check that version number is greater than existing versions, locally and possibly remotely

      repo_for_new_version = aug_ws_branch.create_new_branch_from_this_branch?(get_project(),aug_ws_branch[:repo],new_version)
      create_new_version__type_specific(repo_for_new_version,new_version)
    end

    def update_model_from_clone_changes?(commit_sha,diffs_summary,version=nil)
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return unless pull_was_needed or parse_needed

      update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version)
    end


    def get_project()
      #caching
      return self[:project] if self[:project]
      update_object!(:project_project_id,:display_name) #including :display_name is opportunistic
      if project_id = self[:project_project_id]
        self[:project] = id_handle(:model_name => :project, :id => project_id).create_object()
      end
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
        :cols => [:id,:group_id,:display_name,:branch,:version],
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

   private

    def aggregate_by_remote_namespace(raw_module_rows,opts=Opts.new)
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
      if default = RepoRemote.ret_default_remote_namespace(repo,ret[:repo_remotes])
        repo.consume_remote_repo!(default)
      end
      ret
    end
    
    def get_library_module_branch(version=nil)
      update_object!(:display_name,:library_library_id)
      library_idh = id_handle(:model_name => :library, :id => self[:library_library_id])
      module_name = self[:display_name]
      self.class.get_library_module_branch(library_idh,module_name,version)
    end

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

    def info(target_mh, id, opts={})
      remote_repo_cols = [:id, :display_name, :version, :remote_repos]
      components_cols = [:id, :display_name, :version]
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
        response.sort { |a,b| b[:repo_remote][:created_at] <=> a[:repo_remote][:created_at]}

        # we switch to ascending order
        response.each_with_index do |e,i|
          display_name = (e[:repo_remote]||{})[:display_name]
          prefix = ( i == 0 ? "*" : " ")
          namespaces << { :repo_name => "#{prefix} #{display_name}" }
        end
      end
      
      ret = response.first || {}
      ret.delete_if { |k,v| [:repo,:module_branch,:repo_remote].include?(k) }
      # [Haris] Due to join condition with module.branch we can have situations where we have many versions 
      # of module with same remote branch, with 'uniq' we iron that out

      ret.merge!(:remote_repos => namespaces.uniq ) if namespaces
      ret
    end


    def list(opts=opts.new)
      project_idh = opts.required(:project_idh)
      sp_hash = {
        :cols => [:id, :display_name, :remote_repos_simple],
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      mh = project_idh.createMH(model_type())
      branch_mh = mh.create_childMH(:module_branch)
      branch_parent_field_name =  branch_mh.parent_id_field_name()
      ndx_module_info = get_objs(mh,sp_hash).inject(Hash.new()){|h,r|h.merge(r[:id] => r)}

      #get version info
      sp_hash = {
        :cols => [branch_parent_field_name,:version],
        :filter => [:and,[:oneof, branch_parent_field_name, ndx_module_info.keys], [:eq,:is_workspace,true]]
      }
      branch_info = get_objs(project_idh.createMH(:module_branch),sp_hash)
      #join in version info
      branch_info.each do |br|
        mod = ndx_module_info[br[branch_parent_field_name]]
        version = ((br[:version].nil? or br[:version] == "master") ? "CURRENT" : br[:version])
        mdl = ndx_module_info[br[branch_parent_field_name]]
        (mdl[:version_array]  ||= Array.new) <<  version
      end
      #put version info in print form
      unsorted = ndx_module_info.values.map do |mdl|
        repo_namespace = mdl[:repo_remote][:display_name] if mdl[:repo_remote]
        (mdl[:linked_remotes] ||= Array.new) <<  repo_namespace

        raw_va = mdl.delete(:version_array)
        unless raw_va.nil? or raw_va == ["CURRENT"]
          version_array = (raw_va.include?("CURRENT") ? ["CURRENT"] : []) + raw_va.reject{|v|v == "CURRENT"}.sort
          mdl.merge!(:version => version_array.join(", ")) #TODO: change to ':versions' after sync with client
        end
        if mdl.respond_to?(:component_type)
          mdl.merge!(:type => mdl.component_type())
        end
        mdl
      end
      unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end


    def add_user_direct_access(model_handle,rsa_pub_key)
      repo_user = RepoUser.add_repo_user?(:client,model_handle.createMH(:repo_user),{:public => rsa_pub_key})
      model_name = model_handle[:model_name]
      
      raise ErrorUsage.new("Provided rsa public key exists already") if repo_user.has_direct_access?(model_name,:donot_update => true)
      repo_user.update_direct_access(model_name,true)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.set_user_rights_in_repos(repo_user[:username],repo_names,DefaultAccessRights)

        repos.map{|repo|RepoUserAcl.update_model(repo,repo_user,DefaultAccessRights)}
      end
    end
    DefaultAccessRights = "RW+"

    def remove_user_direct_access(model_handle,rsa_pub_key)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user),:ssh_rsa_pub_key => rsa_pub_key)
      return unless repo_user

      model_name = model_handle[:model_name]
      return unless repo_user.has_direct_access?(model_name)

      username = repo_user[:username]
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
    def initialize_module(project,module_name,config_agent_type,version=nil)
      project_idh = project.id_handle()
      if module_exists?(project_idh,module_name)
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

    def get_workspace_module_branch(project,module_name,version=nil)
      project_idh = project.id_handle()
      filter = [:and, [:eq, :display_name, module_name], [:eq, :project_project_id, project_idh.get_id()]]
      branch = ModuleBranch.workspace_branch_name(project,version)
      post_filter = proc{|mb|mb[:branch] == branch}
      matches = get_matching_module_branches(project_idh,filter,post_filter)
      if matches.size == 1
        matches.first
      elsif matches.size > 2
        raise Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
      end
    end
    #MOD_RESTRUCT: TODO: may deprecate below for above
    def get_library_module_branch(library_idh,module_name,version=nil)
      filter = [:and, [:eq, :display_name, module_name], [:eq, :library_library_id, library_idh.get_id()]]
      branch = ModuleBranch.library_branch_name(library_idh,version)
      post_filter = proc{|mb|mb[:branch] == branch}
      matches = get_matching_module_branches(library_idh,filter,post_filter)
      if matches.size == 1
        matches.first
      elsif matches.size > 2
        raise Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
      end
    end

    def get_matching_module_branches(mh_or_idh,filter,post_filter=nil)
      sp_hash = {
        :cols => [:id,:display_name,:group_id,:module_branches],
        :filter => filter
      }
      rows = get_objs(mh_or_idh.create_childMH(module_type()),sp_hash).map do |r|
        r[:module_branch].merge(:module_id => r[:id])
      end
      if rows.empty?
        raise ErrorUsage.new("Module does not exist")
      end
      post_filter ? rows.select{|r|post_filter.call(r)} : rows
    end

    def pp_module_name(module_name,version=nil)
      version ? "#{module_name} (#{version})" : module_name
    end

    def create_ws_module_and_branch_obj?(project,repo_idh,module_name,input_version)
      project_idh = project.id_handle()
      ref = module_name
      module_type = model_name.to_s
      mb_create_hash = ModuleBranch.ret_workspace_create_hash(project,module_type,repo_idh,input_version)
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
    #MOD_RESTRUCT: TODO: deprecate below for above
    def create_lib_module_and_branch_obj?(library_idh,repo_idh,module_name,input_version)
      ref = module_name
      mb_create_hash = ModuleBranch.ret_lib_create_hash(model_name,library_idh,repo_idh,input_version)
      version = mb_create_hash.values.first[:version]
      create_hash = {
        model_name.to_s => {
          ref => {
            :display_name => module_name,
            :module_branch => mb_create_hash
          }
        }
      }
      input_hash_content_into_model(library_idh,create_hash)

      module_branch = get_library_module_branch(library_idh,module_name,version)
      module_idh =  library_idh.createIDH(:model_name => model_name(),:id => module_branch[:module_id])
      {:version => version, :module_idh => module_idh,:module_branch_idh => module_branch.id_handle()}
    end

   private
    def get_all_repos(mh)
      get_objs(mh,{:cols => [:repos]}).inject(Hash.new) do |h,r|
        repo = r[:repo]
        h[repo[:id]] ||= repo
        h
      end.values
    end

    def module_exists?(project_idh,module_name)
      unless project_idh[:model_name] == :project
        raise Error.new("MOD_RESTRUCT:  module_exists? should take a project, not a (#{project_idh[:model_name]})")
      end
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :project_project_id, project_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      module_branches = get_obj(project_idh.createMH(model_name()),sp_hash)
    end

  end
end
