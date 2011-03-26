module XYZ
  #This representation captures what input components can be connected to which output components and 
  #how there attributes are functionally related
  #input and output components are specfied by a component_type or a memeber of the component type hierarcy.
  #When a user tries to link to comomponents this datra structure is searched to find a match (and if no match)
  #a link constraint violation raised saying they cannot connect. Matching is based by finding most specfic match (wrt type hierrachy of
  #input component then most specific match of output component
  #NOTE: need to flesh out details related to "inheritance override issues"
  PossibleComponentConnections = {
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

      #NOTE: putting as list of hashes as opposed to just hash in case we decide to use ordere dependent semantics
      :output_components =>
      [
       {
        :mysql__master => { #output component: can be component_type or member of component hiererachy
           ###contraints
           #this is optional and needed to be specified only for constraints beyond the implicit constraint 
           #that input x cannot connect to output y unless they match a 'rule' here (match taking into account 
           #component type hierarchy); 
           :constraints => 

           [], #will put in example later, such as constraint on particular mysql version or that 
           #master and slave components must be same major version

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
           # :__input_component and __output_component used too
           #
           #functions will be close in concept to what is used in cloud formation
           #NOTE: in hash rep may represent fuinctions like {:fn_name => 'fn_name', :args => 'array of args}
           ##
           ## When mapping refernces attributes that do not exist, tehy are automatcally added when link added
           ## Simimilarly when mapping refernces componenst that dont exist, tehy are autoamtically created
           ###
           #NOTE: open issue is best way to handle what will call the 'load balancer keep alive issue' 
           # which is when add for example a new branch to load balancer need config for this new instance (will explain better later)
           #so need a var naming convention to refer to all the attributes associated one of possible many connected attributes
           #This also taps closely into how now inputs that are arrays are treated; the inputs index into array may give handle
           #to use for the instance
           :attribute_mappings =>
           [
            #the input to output mappings are with respect to the input and output components/nodes in rule unless :__parent, 
            # :__input_node or __output_node are used 
            #the mapping can be in terms of base attributes or in terms of unravelled attributes by making 
            #the path (given by a list more than a single array element) example port on a layer 4 sap ref would be [:sap_ref__l4,:port]
            #The meaning of simple mapping is equality; for more complex relatsions functions can be used on the output side
            {:input => [:master_log_ref], :output => [:master_log]},
            
            #this is an example of using __parent; needed because the l4 sap is on the mysql__server component, not the mysql__master
            {:input => [:sap_ref__l4], :output => [:__parent,:mysql__server,:sap__l4]}
           ]
         }
       }]
    },

    #below captures that wordpress can connect to mysql or potsgres server
    :wordpress => {
      :connnection_type => :db,
      :required => true,
      :output_components => 
      [{:mysql__server => {}},
       {:postgresql__server => {}}
      ]
    },


    #example that shows when java app is added a db component is generated for it
    #this shows also example of links that go in both directions , i.e., java_app has both input and output
    #connections to teh db component(s)
    #
    # This introduces teh constract {:related_component => "relation") which returns the component that is
    # unqiuely related to the one in the path; so for example below {:related_component => :db_of} is in path
    #where it is refering to database server (mysql__server or postgres__server etc) and {:related_component => :db_of} 
    #then respectively refers to mysql__db or postgresql__db
    # {:related_component => :db_of} is nested within a create comamdn to indiacet that this is causing a new db to created
    # as opposed to using an existing one
    #
    #NOTE: if theer are components that can have multiple instances on same node and need to refernce one of them need
    #way of referencing it; this is similiar to 'load balancer keep alive issue' adn may be solved by refernce to
    #what is on otehr side of link
    #NOTE: curerntly dont have a create for new attributes; only introduce if need it; (dont think need it because attributes unique
    #and mult instance handled by arrays
    :java_app =>  {
      :connnection_type => :db,
      :required => true,
      :output_components =>
      [
       {:database__server => {
           :attribute_connections => 
           [{
              :input => [:__output_component,{:create => {:related_component => :db_of}},:db_connection_ref], 
              :output => [:__input_componet,:db_connection]
            }]
         }
       }
      ]
    },
    #shows how a default connection currently encoded between a sap_config__l4 and sap__l4 (and handled by 'hard coding') 
    #could be encoded in this representation
    #this also shows use of the node attribute host_addresses

    #NOTE: this is a link that is hidden from end user and between attributes on same component
    :service => {
      :connection_type => :sap_config__l4__to__sap__l4,
      :required => true,
      :output_components =>
      [
       {:service => {
           :constraints => [], #TODO: need to add a constraint saying input and output are same component
           :attribute_connections => 
           [
            {
              :input => [:sap__l4], 
              :output => {
                :fn => :cartesian_concat, 
                :args => [[:sap_config__l4], [:__node,:host_addresses]]
              }
            }]
         }
       }]
    }
  }
end
