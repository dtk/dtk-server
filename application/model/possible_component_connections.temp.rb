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
              :constraints => [],
              :events => 
              [
               {:on_create_link => {
                   :extend_component => {
                     :alias => :mysql_db,
                     :extension_type => :database
                   }
                 }
               }],
              :attribute_mappings => 
              [
            #   {"mysql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_config" => "mysql_db.db_params"}
              ]
            }
          },
          {:postgresql__server => {
              :constraints => [],
              :events => 
              [
               {:on_create_link => {
                   :extend_component => {
                     :alias => :postgresql_db,
                     :extension_type => :database
                   }
                 }
               }],
              :attribute_mappings => 
              [
           #    {"postgresql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_config" => "postgresql_db.db_params"}
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
              :aliases => { #no aliases used in thsi example now
              },
              :constraints => 
              [
               [:eq, "mysql__slave.version", "mysql__server.version"],
               [:component_extended, :master]
              ],
              :events => [],
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
end
