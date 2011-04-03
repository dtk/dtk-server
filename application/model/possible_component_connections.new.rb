module XYZ
  ComponentExternalLinkDefs = {
    :java_webapp => {
      :attributes => [],
      :link_defs => 
      [
       {
         :type => :database, #changed type to refer to conenction type and not necessary tied to component hierarchy 
         #in this case it refers to component type hirerachy, but in second example it does not
         :required => true, 

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
                   :extend_component => {
                     :alias => :postgres_db,
                     :extension_type => :database
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
         :type => :master_connection, #changed type to refer to conenction type and not tied to component hierarchy
         :required => true, 

         :possible_links => 
         [
          {:mysql__server => {
              #allowing a general section for aliases; as well as alias to appear in sections such as an alias for a created item
              #alias is similar to how constants used in a programming language
              :aliases => { #no aliases used in thsi example now
              },
              :constraints => 
              [
               #using the array form for constraints that using internally; 
               #this like the other syntactic forms may be changed without impacting semantics
               #first constraint captures that the two mysql components being linked need to have identical version; 
               #NOTE: did away with the function 'base'; instead by convention if have attribute on extension it can refer also
               #to attributes on the base component; similarly refering to attributes on base component has 'access to' all the attributes
               #on any extened component
               [:eq, "mysql__slave.version", "mysql__server.version"],

               #this captures that the master extension must be instantiated already
               [:component_extended, :master]

               #the other alternative would be to omit this constraint and
               #include an event that instantiated the mysql master extension if it did not exist
               #
               #NOTE: since there is conenction between events and conditions to check in contraints
               #may have tehir synax be closer; so for example alternative would be
               # {:component_extended => {
               #     :extension_type => :master
               #     }
               # }
              ],
              :events => [],
              :attribute_mappings => 
              [
               {"mysql__server.master_log" => "mysql__slave.master_log_ref"},
               {"mysql__server.sap__l4" => "mysql__slave.sap_ref__l4"}
              ]
            }
          }
        ]
       }]
    }
  }
end
