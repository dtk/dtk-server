module XYZ
  PossibelComponentConnections = {
    :mysql__slave => { #input component; can be component_type or member of component hiererachy
      #connection type is so can specify for exampel this is a db connection, monitoring connection, etc; there will be a standard set
      #plus ones that are more special purpose (like db_slave_to_master) and can be user defined like 
      :connection_type => :db_slave_to_master,

      #whether connection to this input is required; by default may make this true, but listed here for illustration
      #this can be at this level or connection mapping level (if for example there is multiple attributes associated
      #with connection and only certain ones are required
      :required => true, 
      
      :mysql__master => { #output component: can be component_type or member of component hiererachy

        ###contraints
        #this is optional and for contarints beyond the implicit constraint that input x cannot connect to output y unless they match
        #a rule here (match taking into account component type hierarchy); may also provide for 
        #"inheritence" override (if multiple matches most specfic one is used; where match is first by input component (tehn output component)
        :constraints => 

        [], #will put in example later, such as constraint on particular mysql version oor that master and slaev isnatnces must be same major version

        ### (additional) attribute mappaings
        #this is optional; by default dont need l4 sap_ref to sap connection; unless it needs to be overwritten as show in this example
        #use a directory style naming convention tied into our path names for unravvled attributes; 
        #plus special symbol :__parent, which in unix directory woudl be euqivalent to ../
        :connection_mappings =>

        [
         #the input to output mappings are with respect to teh input and output components in rule unless __parent is used (on output side)
         #the mapping can be in terms of base attributes or in terms of unravelled attributes by making 
         #the path (given by a list more than a single array element) example port on a layer 4 sap ref would be [:sap_ref__l4,:port]
         #by dfault teh relation between the input and output attributes is equality, but this can be 
         #overwritten by including :relation attribute
         #will explain how this is variant (and more encompassing than) cloud formation when theer is multipel fan-in into an input
         {:input => [:master_log_ref], :output => [:master_log]},

         #this is an example of using __parent; needed because the l4 sap is on the mysql__server component, not the mysql__master
         {:input => [:sap_ref__l4], :output => [:__parent,:mysql__server,:sap__l4]}
          ]
      }
    },

    #below captures that wordpress can connect to mysql or potsgres server
    :wordpress => {
      :connnection_type => :db,
      :required => true,
      {:mysql__server => {}},
      {:postgresql__server => {}}
    }
  }
end
