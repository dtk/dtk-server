module XYZ
  #class methods
  module MigrationMethods #methods that can be called within a migration

    #if model_names given then just (re)building these tables
    def db_rebuild(db,model_names=nil,opts=Opts.new)
      #if model_naems check all are defined
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
      #associate database handle DBInstance with all models
      if model_names
        set_db_for_specfic_models(db,model_names)
      else
        set_db_for_all_models(db)
      end

      #setup infra tables if they don't exist already
      setup_infrastructure_tables?(db)
      
      # create the domain-related tables if tehy don't exist already
      dir = :up
      if model_names
        migrate_specfic_models(dir,model_names)
      else
        migrate_all_models(dir)
      end
      # add the top level factorories if they don't exist
      #has to be done after db added to class and models been added
      IDInfoTable.add_top_factories?() 
    end

    #TODO: this is specific migration; will have this subsumed and removed
    def migrate_data(db)
      puts "Migrating data ... "

      c = 2

      columns = [ :id, :display_name, :repos ]

      modules  = Model.get_objs(ModelHandle.new(c, :component_module), { :cols => columns})
      services = Model.get_objs(ModelHandle.new(c, :service_module), { :cols => columns})
      components = modules + services

      raise "No data to migrate, exiting ..." if components.empty?

      repo_remote_mh = components.first[:repo].model_handle(:repo_remote)

      components.each do |e|

        # if remote records exists
        if e[:repo][:remote_repo_name]

          # there seems to be a bug with old data that does not have remote namespace entered in that case
          # we extract it from remote_repo_name
          remote_namespace = e[:repo][:remote_repo_namespace] || e[:repo][:remote_repo_name].match(/^(.*?)\-\-/)[1]

          repo_data = RepoRemote.get_remote_repo(repo_remote_mh, e[:repo][:id], e[:display_name],remote_namespace)

          if repo_data.nil?
            data = RepoRemote.create_repo_remote(repo_remote_mh, e[:display_name], e[:repo][:remote_repo_name], remote_namespace, e[:repo][:id])
            puts "Remote Repo migrated for => '#{data[:display_name]}'"
          end
        end
      end

    end

  end
end
