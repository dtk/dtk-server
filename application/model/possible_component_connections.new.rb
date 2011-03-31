module XYZ
  #This representation captures how components can be connected together, requuirements about what must be connected
  #and deatils about how there attributes assocaited with the components are functionally related
  #input and output components are specfied by a component_type or a memeber of the component type hierarcy.
  #When a user tries to link to comomponents this datra structure is searched to find a match (and if no match)
  #a link constraint violation raised saying they cannot connect. Matching is based by finding most specfic match (wrt type hierrachy of
  #input component then most specific match of output component
  #NOTE: need to flesh out details related to "inheritance override issues"
  ComponentLinkDefs = {
    :java_app => { #NOTE: referered by ':java_app' or if connection between same type of componentr use :alias
      :component_connections =>  #this lists the possible and required type of component compnenctions (e.g.g., database, monitor, etc
      [{ 
         :type => :database, #this is a component type or member of teh component type hierarchy
         :required => true, #indicates that is required that java_app must be connected to a database component
         :possible_instantiations => { #lists the possible component type or member of the component type hierarchy that in this case are the
           #possible databases that one can connect to
           :mysql__server => {
             :constraints => [], #will put in example later, such as constraint on particular mysql version
             :events =>
             [{
                :type => :create_component,
                :parent => {:node_of => :mysql__server},
                :component => {:database_of => :mysql__server},
                :alias => :mysql_db
              }],
             :attribute_mappings => 
             [
              {"mysql__server.sap__l4" => "java_app.sap_ref__l4"},
              {"java_app.db_config" => "mysql_db.db_params"}
             ]
           },
           :postgresql__server => {
             :constraints => [], #will put in example later, such as constraint on particular postgresql version
             :events =>
             [{
                :type => :create_component,
                :parent => {:node_of => :postgresql__server},
                :component => {:database_of => :postgresql__server},
                :alias => :postgresql_db
              }],
             :attribute_mappings => 
             [
              {"postgresql__server.sap__l4" => "java_app.sap_ref__l4"},
              {"java_app.db_config" => "postgresql_db.db_params"}
             ]
           }
         }
       }]
    }
  }
end
