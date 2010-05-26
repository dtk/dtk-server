

module XYZ
  class Admin < Controller

    #TODO: figure out proper place/naming for function calls for db install/setup steps
    def dbrebuild
      #Better encapsulate where case on whetehr production set (meaning that don't need to recreate tables)
      #associate DB with all models
      XYZ::Model.set_db_for_all_models(DB)
      
      #setup infra tables if they don't exist already
      XYZ::Model.setup_infrastructure_tables?(DB)
      
      # create the domain-related tables if tehy don't exist already
      XYZ::Model.migrate_all_models(:up) 
      
      # add the top level factorories if they don't exist
      #has to be done after db added to class and models been added
      XYZ::IDInfoTable.add_top_factories?() unless XYZ::Config[:production]

    end
  end
end