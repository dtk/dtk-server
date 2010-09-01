module XYZ
  #class methods
  module MigrationMethods #methods that can be called within a migration

    def db_rebuild(db)
      #associate database handle DBInstance with all models
      set_db_for_all_models(db)

      #setup infra tables if they don't exist already
      setup_infrastructure_tables?(db)
      
      # create the domain-related tables if tehy don't exist already
      migrate_all_models(:up) 
      
      # add the top level factorories if they don't exist
      #has to be done after db added to class and models been added
      IDInfoTable.add_top_factories?() 

    end

  end
end

