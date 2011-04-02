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
#seems like the event is in terms of what action is to be taken, not what has been taken?
    #for instance, event definition is on creation of link, and action is creating db component
#being a component def, seems redundant to call it create_component if in terms of event not action
#                 :type => :on_create,
#is there a scenario where the parent wouldnt be that of the of the link def?
                 :parent => {:node_of => :mysql__server},
#is it necessary to say to create a database of mysql__server on link of type mysql__server?
                 :component => {:database_of => :mysql__server},
#what is alias used for?
                 :alias => :mysql_db
               }
              ],
              :attribute_mappings => 
              [
               {"mysql__server.sap__l4" => "java_webapp.sap_ref__l4"},
#db_params seems a bit vague/generic as a name, assuming that is db user/pass?
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
