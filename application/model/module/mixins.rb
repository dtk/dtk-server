module DTK
  class ModuleRepoInfo < Hash
    def initialize(repo,module_name,module_idh,branch_obj,version=nil)
      super()
      repo_name = repo.get_field?(:repo_name)
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

  #includes for both class and instance mixins
  module ModuleMixins
    r8_nested_require('mixins','remote')  
    r8_nested_require('mixins','create')  
  end
    
 #instance mixins
  module ModuleMixin
    include ModuleMixins::Remote::Instance
    include ModuleMixins::Create::Instance

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
    #
    # returns Array with: name, namespace, version
    #
    def get_basic_info(opts=Opts.new)
      sp_hash = {
        :cols => [:id, :display_name, :version, :remote_repos],
        :filter => [:eq,:id, id()]
      }

      rows = get_objs(sp_hash)
      unless match = GetBasicInfo.find_match(rows,opts)
        raise Error.new("Unexpected that there is no info associated with module")
      end
      match
    end

    module GetBasicInfo
      #
      # returns Array with: name, namespace, version
      #
      def self.find_match(rows,opts)
        remote_namespace = opts[:remote_namespace]
        match = 
          if rows.size == 1
            rows.first
          elsif rows.size > 1
            rows.find{|r| remote_namespace_match?(r,remote_namespace)}
          end
        if match
          name_namespace_version(match)
        end
      end

     private
      def self.name_namespace_version(row)
        [row[:display_name], remote_namespace(row), (row[:module_branch]||{})[:version]]
      end

      def self.remote_namespace_match?(row,remote_namespace=nil)
        if remote_namespace
          remote_namespace(row) == remote_namespace
        else
          repo_remote(row)[:is_default]
        end
      end

      def self.repo_remote(row)
        row[:repo_remote]||{}
      end
      def self.remote_namespace(row)
        repo_remote(row)[:repo_namespace]
      end
    end

    ##
    # Returns local and remote versions for module
    #
    def local_and_remote_versions(client_rsa_pub_key = nil, opts={})
      Log.error("TODO: see if namespace treatment must be updated")
      module_name, remote_versions = nil, []

      # get local versions list 
      local_versions = get_objs(:cols => [:version_info]).map do |r| 
        v = r[:module_branch].version()
        v.nil? ? "CURRENT" : v
      end
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

    def get_linked_remote_repos(opts={})
      (get_augmented_workspace_branch(opts.merge(:include_repo_remotes => true))||{})[:repo_remotes]||[]
    end

    def get_augmented_workspace_branch(opts={})
      version = (opts[:filter]||{})[:version]
      version_field = ModuleBranch.version_field(version) #version can be nil
      sp_hash = {
        :cols => [:display_name,:workspace_info_full]
      }
      module_rows = get_objs(sp_hash).select do |r|
        r[:module_branch][:version] == version_field
      end
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
      ret = module_obj[:module_branch].merge(:repo => module_obj[:repo],:module_name => module_obj[:display_name])
      if opts[:include_repo_remotes]
        ret.merge!(:repo_remotes => module_obj[:repo_remotes])
      end
      ret
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

    def update_model_from_clone_changes?(commit_sha,diffs_summary,version,opts={})
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)
      parse_needed = (opts[:force_parse] or !dsl_parsed?())
      return unless pull_was_needed or parse_needed

      opts_update = Aux.hash_subset(opts,[:do_not_raise,:modification_type,:force_parse])
      response = update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts_update)
      if ErrorUsage::Parsing.is_error?(response)
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

    #TODO: ModuleBranch::Location : need to paramterize this on branch
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

      raw_module_rows.first.merge(:repo_remotes => repo_remotes)
    end

   private
    def library_branch_name(version=nil)
      library_id = update_object!(:library_library_id)[:library_library_id]
      library_idh = id_handle(:model_name => :library, :id => library_id)
      ModuleBranch.library_branch_name(library_idh,version)
    end
  end

  #class mixins
  module ModuleClassMixin
    r8_nested_require('mixins','list_method_helpers')

    include ModuleMixins::Remote::Class
    include ModuleMixins::Create::Class
    def component_type()
      Log.error("#TODO: ModuleBranch::Location: depreate for this being in ModuleBranch::Location local params")
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
      response = ListMethodHelpers.aggregate_detail(response,project_idh,model_type(),Opts.new(:include_versions => true))

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
      remote_repo_base   = opts[:remote_repo_base]
      include_remotes    = opts.array(:detail_to_include).include?(:remotes)
      include_versions   = opts.array(:detail_to_include).include?(:versions)
      include_any_detail = ((include_remotes or include_versions) ? true : nil)

      cols = [:id, :display_name, :dsl_parsed, include_any_detail && :module_branches_with_repos].compact
      unsorted_ret = get_all(project_idh,cols)
      filter_list!(unsorted_ret) if respond_to?(:filter_list!)
      unsorted_ret.each{|r|r.merge!(:type => r.component_type()) if r.respond_to?(:component_type)}
      if include_any_detail
        opts_aggr = Opts.new(
          :include_remotes => include_remotes,
          :include_versions => include_versions, 
          :remote_repo_base => remote_repo_base,
          :diff => diff
        )
        unsorted_ret = ListMethodHelpers.aggregate_detail(unsorted_ret,project_idh,model_type(),opts_aggr)
      end
      unsorted_ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def get_all(project_idh,cols=nil)
      sp_hash = {
        :cols => add_default_cols?(cols),
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      mh = project_idh.createMH(model_type())
      get_objs(mh,sp_hash)
    end

    def add_user_direct_access(model_handle,rsa_pub_key,username=nil)
      repo_user,match = RepoUser.add_repo_user?(:client, model_handle.createMH(:repo_user),{:public => rsa_pub_key},username)
      model_name = model_handle[:model_name]

      repo_user.update_direct_access(model_name,true)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.set_user_rights_in_repos(repo_user[:username],repo_names,DefaultAccessRights)

        repos.map{|repo|RepoUserAcl.update_model(repo,repo_user,DefaultAccessRights)}
      end
      return match, repo_user
    end

    DefaultAccessRights = "RW+"

    def remove_user_direct_access(model_handle,username)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user),:username => username)
      raise ErrorUsage.new("User '#{username}' does not exist") unless repo_user
      # return unless repo_user

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

    def module_repo_info(repo,module_and_branch_info,version)
      info = module_and_branch_info #for succinctness
      branch_obj = info[:module_branch_idh].create_object()
      ModuleRepoInfo.new(repo,info[:module_name],info[:module_idh],branch_obj,version)
    end

    #can be overwritten
    #TODO: ModuleBranch::Location: deprecate 
    def module_specific_type(config_agent_type)
      module_type()
    end
    private :module_specific_type

    def get_module_branch_from_local(local,opts={})
      project = local.project()
      project_idh = project.id_handle()
      filter = [:and, [:eq, :display_name, local.module_name], [:eq, :project_project_id, project_idh.get_id()]]
      branch = local.branch_name()
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
    #TODO: ModuleBranch::Location: deprecate below for above
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
    def get_workspace_module_branches(module_idhs)
      ret = Array.new
      if module_idhs.empty?
        return ret
      end
      mh = module_idhs.first.createMH()
      filter = [:oneof,:id,module_idhs.map{|idh|idh.get_id()}]
      post_filter = proc{|mb|!mb.assembly_module_version?()}
      get_matching_module_branches(mh,filter,post_filter)
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
