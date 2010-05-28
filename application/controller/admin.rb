

module XYZ
  class AdminController < Controller

    #TODO: figure out proper place/naming for function calls for db install/setup steps
    def dbrebuild
      #associate database handle DBInstance with all models
      Model.set_db_for_all_models(DBinstance)

      #setup infra tables if they don't exist already
      Model.setup_infrastructure_tables?(DBinstance)
      
      # create the domain-related tables if tehy don't exist already
      Model.migrate_all_models(:up) 
      
      # add the top level factorories if they don't exist
      #has to be done after db added to class and models been added
      IDInfoTable.add_top_factories?() unless Config[:production]
      "database rebuild finished"
    end
  end
end
