module DTK; module ModuleMixins
  module Remote
  end

  MODULE_REFS_FILE_NAME = 'module_refs.yaml'

  module Remote::Class
    # install from a dtkn repo; directly in this method handles the module/branc and repo level items
    # and then calls install__process_dsl to handle model and implementaion/files parts depending on what type of module it is
    def install(project, local_params, remote_params, client_rsa_pub_key, opts={})
      version = remote_params.version

      # Find information about module and see if it exists
      local = local_params.create_local(project)
      local_branch = local.branch_name
      local_module_name = local.module_name
      local_namespace   = local.module_namespace_name

      if module_obj = module_exists?(project.id_handle(),local_module_name, local_namespace)
        if module_obj.get_module_branch(local_branch)
          # do not raise exception if user wants to ignore component import
          if opts[:ignore_component_error]
            return module_obj
          else
            message = "Conflicts with existing server local module (#{local_params.pp_module_name()})"
            message += ". To ignore this conflict and use existing module please use -i switch (import-dtkn REMOTE-SERVICE-NAME -i)." if opts[:additional_message]
            raise ErrorUsage.new(message)
          end
        end
      end
      remote = remote_params.create_remote(project)

      remote_repo_handler = Repo::Remote.new(remote)
      remote_repo_info = remote_repo_handler.get_remote_module_info?(client_rsa_pub_key,:raise_error=>true)
      remote.set_repo_name!(remote_repo_info[:git_repo_name])

      # so they are defined outside Transaction scope
      module_and_branch_info = commit_sha = parsed = repo_with_branch = nil

      # outside of transaction only doing read/check operations
      Transaction do
        # case on whether the module is created already
        if module_obj
          # TODO: ModuleBranch::Location: since repo has remote_ref in it must get appopriate repo
          raise Error.new("TODO: ModuleBranch::Location; need to right this")
          repo_with_branch = module_obj.get_repo!()
        else
          # TODO: ModuleBranch::Location: see if this is necessary
          remote_repo_handler.authorize_dtk_instance(client_rsa_pub_key)

          # create empty repo on local repo manager;
          # need to make sure that tests above indicate whether module exists already since using :delete_if_exists
          create_opts = {
            :donot_create_master_branch => true,
            :delete_if_exists => true
            }
          repo_user_acls = RepoUser.authorized_users_acls(project.id_handle())
          repo_with_branch = Repo::WithBranch.create_empty_workspace_repo(project.id_handle(),local,repo_user_acls,create_opts)
        end

        commit_sha = repo_with_branch.initial_sync_with_remote(remote,remote_repo_info)
        # create object in object model that corresponds to remote repo
        create_repo_remote_object(repo_with_branch,remote,remote_repo_info[:git_repo_name])
        module_and_branch_info = create_module_and_branch_obj?(project,repo_with_branch.id_handle(),local)

        module_obj ||= module_and_branch_info[:module_idh].create_object()
        module_branch = module_and_branch_info[:module_branch_idh].create_object()

        opts_process_dsl = {:do_not_raise => true}
        if module_type == :component_module
          opts_process_dsl.merge!(:set_external_refs => true)
        end
        parsed = module_obj.install__process_dsl(repo_with_branch,module_branch,local,opts_process_dsl)
        module_branch.set_sha(commit_sha)
      end
      opts_info = {:version=>version, :module_namespace=>local_namespace}
      response = module_repo_info(repo_with_branch,module_and_branch_info,opts_info)

      if ErrorUsage::Parsing.is_error?(parsed)
        response[:dsl_parsed_info] = parsed
      elsif parsed && !parsed.empty?
        response[:dsl_parsed_info] = parsed[:dsl_parsed_info]
      end
      response
    end

    def delete_remote(project,remote_params,client_rsa_pub_key)
      remote = remote_params.create_remote(project)
      # delete module on remote repo manager
      Repo::Remote.new(remote).delete_remote_module(client_rsa_pub_key)

      # unlink any local repos that were linked to this remote module
      local_module_name = remote.module_name
      local_namespace = remote.namespace # TODO: is this right?
      if module_obj = module_exists?(project.id_handle(),local_module_name, local_namespace)
        repos = module_obj.get_repos().uniq()
        # TODO: ModuleBranch::Location: below looks broken
        # module_obj.get_repos().each do |repo|
        repos.each do |repo|
          # we remove remote repos
          unless repo_remote_db = RepoRemote.get_remote_repo(repo.model_handle(:repo_remote), repo.id, remote.module_name, remote.namespace)
            raise ErrorUsage.new("Remote component/service (#{remote.pp_module_name()}) does not exist")
          end

          repo.unlink_remote(remote)

          RepoRemote.delete_repos([repo_remote_db.id_handle()])
        end
      end
      nil
    end

    def list_remotes(model_handle, rsa_pub_key = nil)
      Repo::Remote.new.list_module_info(module_type(), rsa_pub_key)
    end

    def create_repo_remote_object(repo,remote,remote_repo_name)
      repo_remote_mh = repo.model_handle(:repo_remote)
      opts = Opts.new(:set_as_default_if_first => true)
      RepoRemote.create_repo_remote(repo_remote_mh, remote.module_name, remote_repo_name, remote.namespace, repo.id,opts)
    end
  end

  module Remote::Instance
    class Info < Hash
    end
    # raises an access rights usage error if user does not have access to the remote module
    def get_linked_remote_module_info(project,action,remote_params,client_rsa_pub_key,access_rights,module_refs_content=nil)
      remote = remote_params.create_remote(project)
      repo_remote_handler = Repo::Remote.new(remote)
      remote_module_info = repo_remote_handler.get_remote_module_info?(
        client_rsa_pub_key, {
          :raise_error => true,
          :module_refs_content => module_refs_content
        })

      # we also check if user has required permissions
      # TODO: [Haris] We ignore access rights and force them on calls, this will need ot be refactored since it is security risk
      # to allow permission to be sent from client
      if client_rsa_pub_key
        case action
        when 'push'
          response = repo_remote_handler.authorize_dtk_instance(client_rsa_pub_key, Repo::Remote::AuthMixin::ACCESS_WRITE)
        when 'pull'
          response = repo_remote_handler.authorize_dtk_instance(client_rsa_pub_key, Repo::Remote::AuthMixin::ACCESS_READ)
        end
      end

      unless workspace_branch_obj = remote.get_linked_workspace_branch_obj?(self)
        raise_error_when_not_properly_linked(action,remote)
      end

      ret = Info.new().merge(
          :module_name => remote.module_name,
          :full_module_name => self.full_module_name,
          # TODO: will change this key to :remote_ref when upstream uses this
          :remote_repo => remote.remote_ref,
          :remote_repo_url => remote_module_info[:remote_repo_url],
          :remote_branch => remote.branch_name,
          :workspace_branch => workspace_branch_obj[:branch],
          :dependency_warnings => remote_module_info[:dependency_warnings]
      )
      if version = remote.version
        ret.merge!(:version => version)
      end
      ret
    end

    # publish to a remote repo
    # request_params: hash map containing remote_component_name, remote_component_namespace
    def publish(local_params,remote_params,client_rsa_pub_key)
      project = get_project()
      remote = remote_params.create_remote(project)
      local = local_params.create_local(project)

      unless module_branch_obj = self.class.get_module_branch_from_local(local)
        raise Error.new("Cannot find module_branch_obj from local")
      end

      publish_preprocess_raise_error?(module_branch_obj)

      file_content = nil
      if self.module_type() == :service_module
        # we need to send Repoman information about modules and we do it here
        module_branch = get_workspace_module_branch()
        file_content = repo_file_content(module_branch, MODULE_REFS_FILE_NAME)
      end

      # create module on remote repo manager
      # this wil raise error if it exists already or dont have accsss
      repoman_response = Repo::Remote.new(remote).publish_to_remote(client_rsa_pub_key, file_content)
      remote_repo_name = repoman_response[:git_repo_name]
      remote.set_repo_name!(remote_repo_name)

      # link and push to remote repo
      # create remote repo object
      repo = get_workspace_repo() #TODO: ModuleBranch::Location: need to update get_workspace_repo if can have multiple module branches
      repo.link_to_remote(local,remote)
      repo.push_to_remote(local,remote)

      self.class.create_repo_remote_object(repo,remote,remote_repo_name)
      repoman_response.merge(:remote_repo_name => remote[:module_name])
    end

   private
    def raise_error_when_not_properly_linked(action,remote)
      if action == :push
        raise ErrorUsage.new("Cannot push module (#{module_name()}) to remote namespace (#{remote.namespace}) because it is currently not linked to it")
      else #action == :pull
        raise ErrorUsage.new("Cannot pull module (#{module_name()}) from remote namespace (#{remote.namespace}) because it is currently not linked to it")
      end
    end
  end

end; end

=begin
temporary removed class method
TODO: ModuleBranch::Location: currently cannot be called because this wil be done on client side
    def pull_from_remote(project, local_module_name, remote_repo, version = nil)
      Log.error("Need to cleanup like did for install")
      local_branch = ModuleBranch.workspace_branch_name(project, version)
      module_obj = module_exists?(project.id_handle(), local_module_name)

      # validate presence of module (this should never happen)
      raise ErrorUsage.new("Not able to find local module '#{local_module_name}'") unless module_obj
      # validate presence of brach
      raise ErrorUsage.new("Not able to find version '#{version}' for module '#{local_module_name}'") unless module_obj.get_module_branch(local_branch)

      # TODO: ModuleBranch::Location: since repo has remote_ref in it must get appopriate repo or allow it to be linked to multiple remotes
      repo_with_branch = module_obj.get_repo!
      repo_with_branch.initial_sync_with_remote(remote)

      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),local_module_name,version)
      module_obj.pull_from_remote__update_from_dsl(repo_with_branch, module_and_branch_info, version)
    end
=end
=begin
temporarily removed insatnce methods
TODO: needs to be redone taking into account versions are at same level as base
    # this should be called when the module is linked, but the specfic version is not
    def import_version(remote_repo_base,version)
      parsed = nil
      module_name = module_name()
      project = get_project()
      aug_head_branch = get_augmented_workspace_branch()
      repo = aug_head_branch && aug_head_branch[:repo]
      # TODO:repo.linked_remote? is deprecated
      unless repo and repo.linked_remote?()
        raise ErrorUsage.new("Cannot pull module (#{module_name}) from remote (#{remote_repo_base}) because it is currently not linked to the remote module")
      end
      if get_augmented_workspace_branch(Opts.new(:filter => {:version => version},:donot_raise_error=>true))
        raise ErrorUsage.new("Version (#{version}) for module (#{module_name}) has already been imported")
      end

      local_branch_name = ModuleBranch.workspace_branch_name(project,version)
      Transaction do
        # TODO: may have commit_sha returned in this fn so client can do a reliable pull
        commit_sha = repo.initial_sync_with_remote(remote)
        local_repo_for_imported_version = aug_head_branch.repo_for_version(repo,version)

        opts = {:do_not_raise => true}
        parsed = create_new_version__type_specific(local_repo_for_imported_version,version,opts)
      end
      response = get_workspace_branch_info(version)

      if ErrorUsage::Parsing.is_error?( parsed)
        response[:dsl_parsed_info] = parsed
      else
        response[:dsl_parsed_info] = parsed[:dsl_parsed_info] if (parsed && !parsed.empty?)
      end

      return response
    end
=end

