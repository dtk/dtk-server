r8_nested_require('mixins','remote')
r8_nested_require('mixins','create')
r8_nested_require('mixins','gitolite')
r8_nested_require('utils','list_method')

module DTK

  #
  # Instance Mixins
  #

  module ModuleMixin
    include ModuleMixins::Remote::Instance
    include ModuleMixins::Create::Instance
    include ModuleMixins::Gitolite

    def get_module_branch_from_local_params(local_params,opts={})
      self.class.get_module_branch_from_local(local_params.create_local(get_project()),opts)
    end

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

    def default_linked_remote_repo()
      get_linked_remote_repos(:is_default => true).first
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

      # aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
      unless module_obj = aggregate_by_remote_namespace(module_rows,opts)
        raise ErrorUsage.new("There is no module (#{pp_module_name(version)}) with namespace '#{opts[:filter][:remote_namespace]}' registered on server")
      end
      ret = module_obj[:module_branch].merge(:repo => module_obj[:repo],:module_name => module_obj[:display_name])
      if opts[:include_repo_remotes]
        ret.merge!(:repo_remotes => module_obj[:repo_remotes])
      end
      ret
    end

    # type is :library or :workspace
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
      # caching
      return self[:project] if self[:project]
      update_object!(:project_project_id,:display_name) #including :display_name is opportunistic
      if project_id = self[:project_project_id]
        self[:project] = id_handle(:model_name => :project, :id => project_id).create_object()
      end
    end

    # TODO: ModuleBranch::Location : need to paramterize this on branch
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
      # opportunistically set display name and project_project_id on module
      self[:display_name] ||= row[:display_name]
      self[:project_project_id] ||= row[:project_project_id]
      row[:repo]
    end
    # MOD_RESTRUCT: deprecate below for above
    def get_library_repo()
      sp_hash = {
        :cols => [:id,:display_name,:library_repo,:library_library_id]
      }
      row = get_obj(sp_hash)
      # opportunistically set display name and library_library_id on module
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

    #
    # Returns ModuleBranch object for given version
    #
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

    # MOD_RESTRUCT: may replace below with above
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

    # assumed that all raw_module_rows agree on all except repo_remote
    def aggregate_by_remote_namespace(raw_module_rows,opts={})
      ret = nil
      # raw_module_rows should have morea than 1 row and should agree on all fields aside from :repo_remote
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
      # if filtering by namespace (tested by namespace is non-null) and nothing matched then return ret (which is nil)
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
end