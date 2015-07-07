require 'ap'

module XYZ
  # class methods
  module MigrationMethods #methods that can be called within a migration
    # if model_names given then just (re)building these tables
    def db_rebuild(model_names=nil,opts=Opts.new)
      db = opts[:db]||DB.create(R8::Config[:database])
      # if model_naems check all are defined
      if model_names
        model_names.each do |model_name|
          begin
            Model.model_class(model_name)
          rescue
            error_msg = "Model (#{model_name}) is not defined\n"
            if opts[:raise_error]
              raise Error.new(error_msg)
            else
              puts error_msg
              exit(1)
            end
          end
        end
      end
      # associate database handle DBInstance with all models
      if model_names
        set_db_for_specfic_models(db,model_names)
      else
        set_db_for_all_models(db)
      end

      # setup infra tables if they don't exist already
      setup_infrastructure_tables?(db)

      # create the domain-related tables if tehy don't exist already
      dir = :up
      if model_names
        migrate_specfic_models(dir,model_names)
      else
        migrate_all_models(dir)
      end
      # add the top level factorories if they don't exist
      # has to be done after db added to class and models been added
      IDInfoTable.add_top_factories?()
    end

    def clone_data(git_tenant_name, repo_info_hash, gitoliteMng)
      repo_info_hash.each do |k,v|
        new_url  = "#{git_tenant_name}@localhost:#{v[:new_repo_name]}"
        cmd      = "git --git-dir=#{v[:old_dir]}/.git --work-tree=#{v[:old_dir]} remote add migrate_remote #{new_url}"
        push_cmd = "git --git-dir=#{v[:old_dir]}/.git --work-tree=#{v[:old_dir]} push migrate_remote"
        puts `#{cmd}`
        puts `#{push_cmd}`
        puts "Cloning new repo"
        puts `git clone -b #{v[:branch_name]} #{new_url} #{v[:new_dir]}`
        gitoliteMng.delete_repo(k)
      end

      repo_info_hash.each do |_k,v|
        next unless File.directory?(v[:old_dir])
        puts "Deleting dir #{v[:old_dir]}"
        FileUtils.remove_dir(v[:old_dir])
      end

      gitoliteMng.push()
    end

    def update_all_implementations(c)
      implementations = Model.get_objs(ModelHandle.new(c, :implementation), cols: [:id, :display_name, :repo_id, :repo])
      repo_mh = ModelHandle.new(c, :repo)
      implementations.each do |impl|
        repo = Model.get_by_id(impl[:repo_id], repo_mh, cols: [:id, :display_name, :ref, :repo_name])
        impl.update(
          repo: repo[:repo_name]
        )
      end
    end

    # TODO: this is specific migration; will have this subsumed and removed
    def migrate_data_new(opts, tenant_name, c=2)
      ap "TENANT NAME" + tenant_name
      # PREP VARS
      repos_changes = {}
      db = opts[:db]||DB.create(R8::Config[:database])
      match_username_regex = /^(sm|tm)?\-?(\w+)\-/
      admin_tenant_name     = "dtk-admin-#{tenant_name}"
      git_tenant_name = tenant_name.gsub('dtk','git')

      # SETUP GITOLITE MANAGER
      puts "Migrating data ... "
      overriden_configuration = Gitolite::Configuration.new(
        'conf/repo-configs',
        'conf/group-defs',
        'keydir',
        "/home/#{tenant_name}"
      )
      gitoliteMng = Gitolite::Manager.new("/home/#{tenant_name}/gitolite-admin", overriden_configuration)

      # PROJECT DATA
      default_project = ::DTK::Project.get_all(ModelHandle.new(c, :project)).first

      session = CurrentSession.new
      session.set_user_object(default_project.get_field?(:user))
      session.set_auth_filters(:c,:group_ids)

      # GET ALL THE MODULES
      columns = [ :id, :display_name, :c, :group_id, :repos, :remote_repos]
      modules  = Model.get_objs(default_project.model_handle(:component_module), cols: columns)
      services = Model.get_objs(default_project.model_handle(:service_module), cols: columns)
      tests = Model.get_objs(default_project.model_handle(:test_module), cols: columns)

      components = modules + services + tests
      raise "No data to migrate, exiting ..." if components.empty?

      components.each do |e|
        next if e[:display_name].eql?('.workspace')

        # if remote records exists
        if e[:repo_remote] && e[:repo_remote][:repo_namespace]
          remote_namespace = e[:repo_remote][:repo_namespace]
        else
          remote_namespace = Namespace.default_namespace_name
        end

        remote_namespace_obj = Namespace.find_or_create(default_project.model_handle(:namespace), remote_namespace)

        ref_name = "#{remote_namespace}::#{e[:display_name]}"
        e.update(namespace_id: remote_namespace_obj.id(), ref: ref_name)

        if e[:repo]
          old_repo_name = e[:repo][:repo_name]

          if old_repo_name.nil? || old_repo_name.empty?
            puts "Skipping '#{ref_name}' missing repo name!!!"
            next
          end

          username = old_repo_name.match(match_username_regex)[2]

          if username
            new_repo_name = ModuleBranch::Location::Server::Local.private_user_repo_name(username, e.module_type(), e.module_name(), remote_namespace)

            puts "Successfully updated to namespace convention '#{ref_name}'"

            old_repo = gitoliteMng.open_repo(old_repo_name)
            new_repo = gitoliteMng.open_repo(new_repo_name)

            old_repo.add_username_with_rights(git_tenant_name, "RW+")
            old_repo.add_username_with_rights(admin_tenant_name, "RW+")

            new_repo.rights_hash = old_repo.rights_hash
            new_repo.commit_messages = ["Preparing renaming: '#{old_repo.repo_dir_path}' > '#{new_repo.repo_dir_path}'"]

            new_repo.remove_group('tenants')
            old_repo.remove_group('tenants')

            repos_changes.store(old_repo_name,               new_repo_name: new_repo_name,
              old_dir: "/home/#{tenant_name}/r8server-repo/#{old_repo_name}",
              new_dir: "/home/#{tenant_name}/r8server-repo/#{new_repo_name}",
              branch_name: "workspace-private-#{username}"
                               )

            e[:repo].update(
              ref: new_repo_name,
              display_name: new_repo_name,
              repo_name: new_repo_name,
              local_dir: "/home/#{tenant_name}/r8server-repo/#{new_repo_name}",
              remote_repo_namespace: remote_namespace,
              remote_repo_name: e[:repo_remote] ? e[:repo_remote][:repo_name] : nil
            )
          else
            puts "MISSSING USERNAME!!!!"
          end
        end
      end

      ap repos_changes

      ap "THE PusH"
      ap gitoliteMng.push()

      ap "CLONE DATA"
      clone_data(git_tenant_name, repos_changes, gitoliteMng)

      ap "UPDATE IMPLEMENTATIONS"
      update_all_implementations(c)

      ap "MIGRATE DATE - FINISHED"
    end
  end
end
