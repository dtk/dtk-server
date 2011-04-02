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
                   :instantiate_component => {
                     :alias => :mysql_db,
                     :component => "database_of(template(:mysql__server))",
                     :node => :remote
                   }
                 }
               }],
              :attribute_mappings => 
              [
               {"mysql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_config" => "mysql_db.db_params"}
              ]
            }
          },
          {:postgresql__server => {
              :constraints => [],
              :events => 
              [
               {:on_create_link => {
                   :instantiate_component => {
                     :alias => :postgresql_db,
                     :component => "database_of(template(:postgresql__server))",
                     :node => :remote
                   }
                 }
               }],
              :attribute_mappings => 
              [
               {"postgresql__server.sap__l4" => "java_webapp.sap_ref__l4"},
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
         :type => :mysql__server,
         :required => true, 

         :possible_links => 
         [
          {:mysql__server => {
              :aliases => {
                :master => "extension(:mysql__server,master)"
              },
              :constraints => 
              [
               [:eq, "parent(:mysql__slave).version", "mysql__server.version"],
               [:instantiated, :master]
              ],
              :events => [],
              :attribute_mappings => 
              [
               {"master.master_log" => "mysql__slave.master_log_ref"},
               {"mysql__server.sap__l4" => "mysql__slave.sap_ref__l4"}
              ]
            }
          }
        ]
       }]
    }
  }
end
