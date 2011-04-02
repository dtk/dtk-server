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
               #changed from on_create to on_create_link because theer are other events relevant such as this triggering
               #when a new component is added to a node (this is applicable for an internal link scenario I am working on)
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
              #allowing a general section for aliases; as well as alias to appear in sections such as an alias for a created item
              #alias is similar to how a local variable is used in a programming language
              :aliases => {
                #function extension(component,extension_type) returns the eextension associated with the base component
                #whether or not extensions are tretaed as mixins the extension fn is needed to enforce constraint that an extension
                #must be on a component or to express instatiate (if needed) the master extension 
                :master_ext => "extension(:mysql__server,master)"
              },
              :constraints => 
              [
               #using the array form for constraints that using internally; 
               #this like the other syntactic forms may be changed without impacting semantics
               #first constraint captures that the two mysql components being linked need to have identical version; 
               #the function 'base' is the inverse of 'extension'
               [:eq, "base(:mysql__slave).version", "mysql__server.version"],

               #this captures that the master extension must be instantitaed; the other 
               #alternative would be to omit this constraint and
               #include an event that instantiated the mysql master extension if it did not exist
               #if we did not include the alias def for master_ext; this constraint could be written as 
               # [:instantiated, "extension(:mysql__server,master)"]
               [:instantiated, :master_ext]
              ],
              :events => [],
              :attribute_mappings => 
              [
               {"master_ext.master_log" => "mysql__slave.master_log_ref"},
               #if extensions treated as mixins instead of components with their own attributes, then would be written by
               # {"master__server.master_log" => "mysql__slave.master_log_ref"}

               {"mysql__server.sap__l4" => "mysql__slave.sap_ref__l4"}
              ]
            }
          }
        ]
       }]
    }
  }
end
