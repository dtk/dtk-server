module XYZ
  ComponentExternalLinkDefs = {
    :java_webapp => {
      :attributes => [],
      :link_defs => 
      [
       {
         :type => :database, #this is a component type or member of teh component type hierarchy
         :required => true, #indicates that is required that java_app must be connected to a database component

         :possible_links => 
         [
          {:mysql__server => {
              :events => { 
                :on_create_link => 
                [{
                   :extend_component => {
                     :alias => :mysql_db,
                     :extension_type => :database
                   }
                 }]
              },
              :attribute_mappings => 
              [
            #   {"mysql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_params" => "mysql_db.db_params_ref"}
              ]
            }
          },
          {:postgresql__server => {
              :events => {
                :on_create_link =>
                [{
                   :extend_component => {
                     :alias => :postgresql_db,
                     :extension_type => :database
                   }
                 }]
              },
              :attribute_mappings =>
              [
               #   {"postgresql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_params" => "postgresql_db.db_params_ref"}
              ]
            }
          }
        ]
       }]
    },
    :mysql__slave => {
      :attributes => [],
      :link_defs => 
      [
       {
         :type => :master_connection, 
         :required => true, 

         :possible_links => 
         [
          {:mysql__server => {
              :constraints => 
              [
               [:extension_exists, ":mysql__server", "master"],
               [:eq, ":mysql__slave.version", ":mysql__server.version"],

               [:eq, ":mysql__slave.sap_ref__l4.cardinaity", 1]
               #alt form would be 
               #[:link_cardinality, ":mysql__slave.sap_ref__l4", 1] 
              ],
              :attribute_mappings => 
              [
               {"mysql__server.master_log" => "mysql__slave.master_log_ref"},
             #  {"mysql__server.sap__l4" => "mysql__slave.sap_ref__l4"}
              ]
            }
          }
        ]
       }]
    }
  }
  #TODO: making very simple and symetric now; wil figure out how to align with external links
  IntraNodeConnections = {
    :mysql__server => {
      :nagios__client  => {
        :attribute_mappings => 
        [
         #with seperate db this would be mysql__server.db_params[database=monitor]
         {"mysql__server.monitor_db_params" => 
           "nagios__client.service_check_input.mysql[:component_index].db_params_ref"},
         {"mysql__server.sap_config__l4.0.port" =>
           "nagios__client.service_check_input.mysql[:component_index].port"}
        ]
      }
    }
  }
end
