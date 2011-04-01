module XYZ
  model_defs = {
    :java_app => {
      :attributes => [],
      :link_def => {
        :type => :database, #this is a component type or member of teh component type hierarchy
        :required => true, #indicates that is required that java_app must be connected to a database component

        :links => [
          {
            :mysql__server => {
              :constraints => [],
              :events => [
                {
                  :type => :create_component,
                  :parent => {:node_of => :mysql__server},
                  :component => {:database_of => :mysql__server},
                  :alias => :mysql_db
                }
              ],
              :attribute_mappings => [
                {"mysql__server.sap__l4" => "java_app.sap_ref__l4"},
                {"java_app.db_config" => "mysql_db.db_params"}
             ]
           }
          },
          {
            :postgresql__server => {
              :constraints => [], #will put in example later, such as constraint on particular postgresql version
              :events => [
                {
                  :type => :create_component,
                  :parent => {:node_of => :postgresql__server},
                  :component => {:database_of => :postgresql__server},
                  :alias => :postgresql_db
                }
              ],
              :attribute_mappings => [
                {"postgresql__server.sap__l4" => "java_app.sap_ref__l4"},
                {"java_app.db_config" => "postgresql_db.db_params"}
             ]
           }
          }
        ]
      },

#TODO: flush out monitoring/service check definitions in more detail
      :service_check_defs => { 
         :type => :monitoring_server, 
         :required => false, 
         :possible_instantiations => { 
           :nagios__server => { #TODO: ...
           }
         }
      }
    }
  }

end
