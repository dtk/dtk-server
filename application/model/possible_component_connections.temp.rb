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
               {
                 :type => :create_component,
                 :parent => {:node_of => :mysql__server},
                 :component => {:database_of => :mysql__server},
                 :alias => :mysql_db
               }
              ],
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
               {
                 :type => :create_component,
                 :parent => {:node_of => :postgresql__server},
                 :component => {:database_of => :postgresql__server},
                 :alias => :postgresql_db
               }
              ],
              :attribute_mappings => 
              [
               {"postgresql__server.sap__l4" => "java_webapp.sap_ref__l4"},
               {"java_webapp.db_config" => "postgresql_db.db_params"}
              ]
            }
          }
        ]
       }]
    }
  }
end
