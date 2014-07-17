r8_nested_require('mixins','remote')
r8_nested_require('mixins','create')
r8_nested_require('mixins','gitolite')
r8_nested_require('utils','list_method')

module DTK
  #
  # Class Mixins
  #
  module ModuleClassMixin

    include ModuleMixins::Remote::Class
    include ModuleMixins::Create::Class


    def component_type()
      Log.info_pp(["#TODO: ModuleBranch::Location: deprecate for this being in ModuleBranch::Location local params",caller[0..4]])
      case module_type()
       when :service_module
        :service_module
       when :component_module
        :puppet #TODO: hard wired
       when :test_module
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
        # TODO: need to make more sophisticated so we dont end up comparing a '' to a date
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
      response = ModuleUtils::ListMethod.aggregate_detail(response,project_idh,model_type(),Opts.new(:include_versions => true))

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
        unsorted_ret = ModuleUtils::ListMethod.aggregate_detail(unsorted_ret,project_idh,model_type(),opts_aggr)
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

    def remove_user_direct_access(model_handle, username)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user),:username => username)
      raise ErrorUsage.new("User '#{username}' does not exist") unless repo_user
      # return unless repo_user

      model_name = model_handle[:model_name]
      return unless repo_user.has_direct_access?(model_name)

      # confusing since it is going to gitolite
      RepoManager.delete_user(username)

      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.remove_user_rights_in_repos(username,repo_names)
        # repo user acls deleted by foriegn key cascade
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

    # can be overwritten
    # TODO: ModuleBranch::Location: deprecate
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
    # TODO: ModuleBranch::Location: deprecate below for above
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