module XYZ
  #This representation captures what input components can be connected to which output components and 
  #how there attributes are functionally related
  #input and output components are specfied by a component_type or a memeber of the component type hierarcy.
  #When a user tries to link to comomponents this datra structure is searched to find a match (and if no match)
  #a link constraint violation raised saying they cannot connect. Matching is based by finding most specfic match (wrt type hierrachy of
  #input component then most specific match of output component
  #NOTE: need to flesh out details related to "inheritance override issues"
  PossibelComponentConnections = {
    :mysql__slave => { #input component; can be component_type or member of component hiererachy

      #connection type is so can specify, for example 'this is a db connection', monitoring connection, etc; 
      #there will be a standard set of connections plus ones that are more special purpose 
      #(like db_slave_to_master) and can be user defined like 
      #NOTE: may allow these to also be at the connection_mapping level
      :connection_type => :db_slave_to_master,

      #:required captures whether connection to this input is required; by default may make this true, but listed here for illustration
      #this can be at this level or connection mapping level (if for example there is multiple attributes associated
      #with connection and only certain ones are required
      :required => true, 
      
      :mysql__master => { #output component: can be component_type or member of component hiererachy

        ###contraints
        #this is optional and needed to be specified only for constraints beyond the implicit constraint 
        #that input x cannot connect to output y unless they match a 'rule' here (match taking into account 
        #component type hierarchy); 
        :constraints => 

        [], #will put in example later, such as constraint on particular mysql version or that master and slave components must be same major version

        ### (additional) attribute mappings
        #this is optional; by default dont need l4 sap_ref to sap connection; unless it needs to be overwritten as shown in this example
        #the basic building blocks for these attribute mapapings is path specification that identifies a component or node 
        #attribute and functions that can combine paths (and also can be nested) 
        #for paths a directory style naming convention tied into our path names for unravvled attributes; 
        #plus a few special symbols 
        #   :__parent, which in unix directory woudl be euqivalent to ../
        # :__node - represents the node that component is on and used to access node attributes
        # :__input_node and __output_node which as wil be illustarettd below used when a relationship between components need links
        # that point in both directions
        #functions will be close in concept to what is used in cloud formation
        #NOTE: in hash rep may represent fuinctions like {:fn_name => 'fn_name', :args => 'array of args}
        ##
        ## When mapping refernces attributes that do not exist, tehy are automatcally added when link added
        ## Simimilarly when mapping refernces componenst that dont exist, tehy are autoamtically created
        #NOTE: open issue is best way to handle what will call the 'load balancer keep alive issue' 
        # which is when add for example a new branch to load balancer need config for this new instance (will explain better later)
        #so need a var naming convention to refer to all teh attributes associated one of possible many connected attributes
        :attribute_mappings =>

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
