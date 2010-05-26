require File.expand_path('model',  File.dirname(__FILE__))

module XYZ
  #TBD: whether to keep attribute_def and if so deciding what to go in attribute_def vs attribute
  #TBD: some of these attributes are only on executable nodes so may have subclasses
  class AttributeDef < Model
    set_relation_name(:attribute,:attribute_def)

    class << self
      def up()
        column :default, :json
        column :data_type, :varchar, :size => 25
        #TBD: whether to explicitly have an array or put this in data type or seamntic_type
        column :is_array, :boolean, :default => false
        column :semantic_type, :json
        column :hidden, :boolean, :default => false
        column :port_type, :varchar, :size => 10 # null means no port; otherwise input or output
        column :external_attr_ref, :text
        many_to_one :component_def
      end
    end
  end

  #TBD: for efficiency think want to cache some virtual column calls 
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    class << self
      def up()
        column :value_asserted, :json
        column :value_derived, :json
        column :function, :json
        column :propagation_type, :varchar, :size => 20, :default => "immediate" #whether a propagated new value should be immediately set or whether it needs to go through approval, etc
        column :constraints, :text
        column :required, :boolean #whether required for this attribute to have a value inorder to execute actions for parent component; TBD: may be indexed by action

        virtual_column :attribute_value 
        virtual_column :semantic_type
        virtual_column :is_array

        virtual_column :external_attr_ref
        virtual_column :port_type
        virtual_column :data_type

        #TBD: may take out "?" in columns because sql does not allow this; so not transparent
        virtual_column :hidden?

        #Boolean that indicates whether there is a executable script/recipe associated with the attribute
        virtual_column :executable? 
        virtual_column :unknown_in_attribute_value 

        #if component attribute then hash with component and node(s) associated with it 
        virtual_column :assoc_components_on_nodes  
        foreign_key :attribute_def_id, :attribute_def, FK_CASCADE_OPT
        many_to_one :component, :node
      end
    end

    ###### Instance fns
    def get_attribute_def(opts={})
      return nil if self[:attribute_def_id].nil?
      get_object_from_db_id(self[:attribute_def_id],:attribute_def)
    end

    def check_and_set_derived_relation!()
      ingress_objects = Object.get_objects(:attribute_link,id_handle[:c],:output_id => self[:id])
      return nil if ingress_objects.nil?
      ingress_objects.each{ |input_obj|
        fn = AttributeLink::ret_function_if_can_determine(input_obj,self)
        check_and_set_derived_rel_from_link_fn!(fn)
      }
    end

    #sets this attribute derived relation from fn given as input; if error throws trap
    #TBD: may want to pass in more context about input so that can set fn
    def check_and_set_derived_rel_from_link_fn!(fn)
      return nil if fn.nil?
      if self[:function].nil?
        update(:function => fn)
        return nil
      end
      raise Error.new("mismatched link") 
    end


   private

    ### virtual column defs
    # returns asserted first then derived
    def attribute_value()
      self[:value_asserted] || self[:value_derived]
    end

    def semantic_type()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:semantic_type] : nil
    end

    def is_array()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:is_array] : nil
    end

    def unknown_in_attribute_value()
      attr_value = attribute_value()
      return true if attr_value.nil?
      return nil unless is_array
      return nil unless attr_value.kind_of?(Array) #TBD: this should be error      
      attr_value.each{|v| return true if v.nil?}
      return nil
    end

    def external_attr_ref()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:external_attr_ref] : nil
    end

    def hidden?()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:hidden] : nil
    end

    def port_type()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:port_type] : nil
    end

    def data_type()
      attr_def = get_object_attribute_def()
      attr_def ? attr_def[:data_type] : nil
    end
    
    def executable?()
      external_attr_ref().nil? ? false : true
    end

    def assoc_components_on_nodes()
      parent_obj = get_parent_object()	
      return [] if parent_obj.nil?
      case parent_obj.relation_type
        when :node
          []
        when :component
          parent_obj.get_objects_associated_nodes().map{|n|
            {:node => n, :component => parent_obj}
          }
        else
          raise Error.new("unexpected parent of attribute")
      end 
    end    

    #######
    def get_object_attribute_def()
      return nil if self[:attribute_def_id].nil?
      guid = IDInfoTable.ret_guid_from_db_id(self[:attribute_def_id],:attribute_def)
      Object.get_object(IDHandle[:c => id_handle[:c], :guid => guid])
    end
  end
  #END AttributeDef Class definition

  class AttributeLink < Model
    set_relation_name(:attribute,:link)

    class << self
      def up()
        foreign_key :input_id, :attribute, FK_CASCADE_OPT
        foreign_key :output_id, :attribute, FK_CASCADE_OPT
        column :label, :text, :default => "1"
        has_ancestor_field()
        many_to_one :project, :library, :deployment, :component
      end

      #TBD: many of these fns may get moved to utils area (as class mixins)
      ##### Actions

      def create(target_id_handle,input_id_handle,output_id_handle,href_prefix,opts={})
        raise Error.new("Target location (#{target_id_handle}) does not exist") unless exists? target_id_handle

        input_obj = Object.get_object(input_id_handle)
        raise Error.new("Input endpoint does not exist") if input_obj.nil?
        i_ref = input_obj.get_qualified_ref

        output_obj = Object.get_object(output_id_handle)
        raise Error.new("Output endpoint does not exist") if output_obj.nil?
        o_ref = output_obj.get_qualified_ref

        link_content = {:input_id => input_obj[:id],:output_id => output_obj[:id]}
        link_ref = (i_ref.to_s + "_" + o_ref.to_s).to_sym

        factory_id_handle = get_factory_id_handle(target_id_handle,:attribute_link)
        link_uris = create_from_hash(factory_id_handle,{link_ref => link_content})
        fn = ret_function_if_can_determine(input_obj,output_obj)
        output_obj.check_and_set_derived_rel_from_link_fn!(fn)
        link_uris
      end

      #returns function if can determine from semantic type of input and output
      #throws an error if finds a mismatch
      def ret_function_if_can_determine(input_obj,output_obj)
        i_sem = input_obj[:semantic_type]
        return nil if i_sem.nil?
        o_sem = output_obj[:semantic_type]
        return nil if o_sem.nil?

        #TBD: haven't put in any rules if they have different seamntic types
        return nil unless i_sem.keys.first == o_sem.keys.first      
      
        sem_type = i_sem.keys.first
        ret_function_endpoints_same_type(i_sem[sem_type],o_sem[sem_type])
      end

    private

      def ret_function_endpoints_same_type(i,o)
        #TBD: more robust is allowing for example output to be "database", which matches with "postgresql" and also to have version info, etc
        raise Error.new("mismatched input and output types") unless i[:type] == o[:type]
        return :equal if !i[:is_array] and !o[:is_array]
        return :equal if i[:is_array] and o[:is_array]
        return :concat if !i[:is_array] and o[:is_array]
        raise Error.new("mismatched input and output types") if i[:is_array] and !o[:is_array]
        nil
      end
    end

    ##instance fns
    def get_input_attribute(opts={})
      return nil if self[:input_id].nil?
      get_object_from_db_id(self[:input_id],:attribute)
    end

    def get_output_attribute(opts={})
      return nil if self[:output_id].nil?
      get_object_from_db_id(self[:output_id],:attribute)
    end
  end
  # END Attribute class definition
end
#END module XYZ block def

###############
#TBD: below wil moved to seperate file(s)
=begin

module XYZ
  #each instance is associated with an attribute being processed
  #when created it stores info about its attribute and downstream conncted ones

  class AttributeLinkMessageProcessor < MessageProcessor

    def initialize(attr_id_handle)
      c = attr_id_handle[:c]
      @attr_obj = Shared::Attribute.new(attr_id_handle)

      egress_links = Object.get_objects(:attribute_link,c,:input_id => @attr_obj[:id])
      @egress_obj_ids = (egress_links || []).map{|l| l[:output_id].to_s}
      
      ingress = Object.get_objects(:attribute_link,c,:output_id => @attr_obj[:id])

      @input_objs = {}
      (ingress || []).each{ |link_obj| 
        guid = IDInfoTable.ret_guid_from_db_id(link_obj[:input_id],:attribute_link)
        @input_objs[link_obj[:label]] = Shared::Attribute.new(IDHandle[:c => c,:guid => guid])
      }
    end

    def object_id()
     @attr_obj[:id].to_s
    end

    ######
    # hash_msg can be of form:
    # :propagated_value => {:originating_id => [id], :value => [val]}, or
    # :asserted_value => [value]
    #TBD: refactor with nanite/controller like dispatching syntax
    def process_message(proc_msg)
      case proc_msg.msg_type
        when :propagate_asserted_value
          process_msg_propagate_asserted_value(proc_msg) 
        when :asserted_value
          process_msg_asserted_value(proc_msg)
        when :propagated_value
          process_msg_propagated_value(proc_msg)
        else
          raise Error.new("illegal message received: #{proc_msg.msg_type}")
      end
    end

  private

    def process_msg_propagate_asserted_value(proc_msg)
      asserted_value = @attr_obj[:value_asserted]
      task_set = ret_task_set(proc_msg)
      return task_set if asserted_value.nil?
      add_propagated_value_subtasks!(task_set,asserted_value)
    end

    def process_msg_asserted_value(proc_msg)
      new_value = proc_msg.msg_content
      old_value = @attr_obj[:value_asserted]
      result = Aux::objects_equal?(new_value,old_value) ?
        :no_change : {:new_value => new_value, :old_value => old_value}
      
      task_set = ret_task_set(proc_msg,result)
      return task_set if result == :no_change

      @attr_obj.update(:value_asserted,new_value)
      add_propagated_value_subtasks!(task_set,new_value)
    end

    def process_msg_propagated_value(proc_msg)
      msg_content = proc_msg.msg_content
      fn = @attr_obj[:function]
      raise Error.new("no function to compute derived value found") if fn.nil?

      #derived values cannot override asserted 
      return  ret_task_set(proc_msg,:no_change) if @attr_obj[:value_asserted] 

      #TBD: below is not needed anymore since when computes is getting teh shared value
      #for efficiency though may look at using this agin
      #need to 'untangle' what is msg bus, what is gotten from db and what is gotten from memorycache
      #complicating concern is when load balncing sharing state or when multiple inputs and
      #value in object is this processor would be stale if not using a memory cache or going to db
      #propagated_value = proc_msg[:propagated_value][:value]

      old_value = @attr_obj[:value_derived]
      new_value = recomputed_derived_value(fn)

      if new_value.nil?
        return ret_task_set(proc_msg,:no_input) 
      end
      if Aux::objects_equal?(new_value,old_value)
        return ret_task_set(proc_msg,:no_change)
      end
      
      @attr_obj.update(:value_derived,new_value)
      result = {:new_value => new_value, :old_value => old_value}
      task_set = ret_task_set(proc_msg,result)
      add_propagated_value_subtasks!(task_set,new_value)
    end

    def recomputed_derived_value(fn)
      #TBD: below might have pass through to db if cannot get value from cache
      if fn == "equal"
        raise Error.new("only one input allowed when fn is 'equal'") unless @input_obj.size == 1
        #TBD: a potential efficiency is using instead :value_derived since if single param then this only gets propgated if there is no asserted value
        return @input_obj[0][:attribute_value]
      elsif fn == "concat"
        #TBD: put in multi call
        return @input_objs.map{|label,input_obj|input_obj[:attribute_value]}
      end  
      
      raise ErrorNotImplemented.new("Link propagation using relation #{fn.inspect} not implemented yet") unless fn.kind_of?(Hash)
      
      case fn.keys[0]
        when :predefined
          return recomputed_derived_value_predefine_fn(fn)
      end

      raise ErrorNotImplemented.new("Link propagation using relation #{fn.inspect} not implemented yet")
    end

    #form is  :predefined => {
    #              :name => <name>,
    #              :parameters : [<label list>] or "all"}
    def recomputed_derived_value_predefine_fn(fn)
      lambda_fn = FN_DEF[fn[:predefined][:name].to_sym]
      raise Error.new("cannot find definition of predefined fn #{fn[:predefined][:name]}") if lambda_fn.nil?
      call_as_one_arg,params = ret_params(fn[:predefined][:parameters])
      call_as_one_arg ? lambda_fn.call(params) : lambda_fn.call(*params)
    end

    #TBD: while user-defined fns will be lambda, not clear whetehr extra indirection using lambdas makes coding cleaner
    FN_DEF = {
     :sap_from_config_and_ip =>
       lambda{|ip_addr,sap_config|
          DerivedValueFunction::sap_from_config_and_ip(ip_addr,sap_config)
       },
     :sap_ref_from_sap =>
       lambda{|sap|
          DerivedValueFunction::sap_ref_from_sap(sap)
       },
     :sap_ref_array_from_sap_array =>
       lambda{|sap_array|
          sap_array.map{|sap| DerivedValueFunction::sap_ref_from_sap(sap)}
       }
    }

    # returns [pass_as_one_arg(boolean), param_array]
    def ret_params(param_list)
      if param_list == "all"
        [true,
         @input_objs.map{|label,input_obj|input_obj[:attribute_value]}]
      else
        [false,
         param_list.map{|label|
           raise Error.new("dangling ref: #{label} in param list") if @input_objs[label].nil?
           @input_objs[label][:attribute_value]
         }]
      end
    end

    def ret_task_set(proc_msg,results=nil)
      task_set_opts = results ? {:results => results} : {}
      WorkerTask.create(:task_set,proc_msg,task_set_opts)
    end

   #TBD: a misnomer since this also adds execute on node
    def add_propagated_value_subtasks!(task_set,new_value)
      #add subtasks for all the related output vars
      @egress_obj_ids.each do |egress_obj_id| 
        msg_content = {:originating_id => @attr_obj[:id], :value => new_value}
        object_id = egress_obj_id
        #TBD: can we do away with needing ProcessorMsg on output?
        proc_msg_out = ProcessorMsg.create({
          :msg_type => :propagated_value,
          :msg_content =>msg_content,
          :target_object_id => object_id
        })
        task = WorkerTask.create(:basic,proc_msg_out)
        task_set.add_task(task)
      end
      add_execute_on_node_subtask!(task_set,new_value)
      task_set
    end

    #TBD: move code that checks if all required paramters are present and if so
    #forms an :execute_on_node msg to a system file
    #if attribute is executable then msg is sent to the associated node
    def add_execute_on_node_subtask!(task_set,new_value)
      if @attr_obj[:executable?]
        assoc_cmps_nodes = @attr_obj[:assoc_components_on_nodes]
        assoc_cmps_nodes.each do |cmp_node|
        attr_vals = attr_values_if_precoditions_hold(cmp_node[:component],new_value)

        if attr_vals
          proc_msg_out = ProcessorMsg.create({
            :msg_type => :execute_on_node,
            :msg_content => {:external_cmp_ref => cmp_node[:component][:external_cmp_ref],
	          :attribute_values => attr_vals},
            :target_object_id => cmp_node[:node][:id]
          })
          task = WorkerTask.create(:basic,proc_msg_out)
          task_set.add_task(task)
        else
          #TBD: may indicate exactly which attributes missing values
          task_set.add_log_entry(:preconditions_do_not_hold,{:component_id => cmp_node[:component][:id]})
        end
      end
    end

end

    
    #returns non null value if all the component's preconditions hold; if so
    #will returns a hash with values of these attributes
    #TBD: use memcache    
    def attr_values_if_precoditions_hold(cmp_object,new_value)
      raw_ret = cmp_object.get_direct_attribute_values(:value, {:attr_include => [:external_attr_ref,:required,:unknown_in_attribute_value]})
      #test to see if preconditions is whether the attribute is required and does not have an unknown value
      ret = {}
      raw_ret.each do |var_name,values|
        if values[:required] 
          return nil if values[:unknown_in_attribute_value]
          ret[var_name] = {:value => values[:value], :external_attr_ref => values[:external_attr_ref]}
        end
      end
      ret
    end

    #TBD: this is to give interface to get at value of of attribute that hide whether coming from db
    #or cache; decison based on whtheer a property is static of changing
    #'shared' below means that other processors may be sharing the object
    class Shared
      class Attribute
        def initialize(id_handle)
          @id_handle = id_handle
          #below will have all properties, but only static ones will be accessed
          @obj_static_properties = Object.get_object(@id_handle)
          @id = @obj_static_properties[:id]
        end

        def [](x)
          #if changing value then go to cache first and then db; otherwise go to db
          case x
            when :id #for efficiency
              @id
            when :value_asserted, :value_derived
              get_from_cache_then_db_and_set_cache(x)
            when :attribute_value #TBD: encapsulate better so can avoid rewriting fn below
              get_from_cache_then_db_and_set_cache(:value_asserted) ||
              get_from_cache_then_db_and_set_cache(:value_derived)		               
            else
              @obj_static_properties[x]
          end 
        end

        #TBD: better encapsulate with above
        def update(x,val)
          #below looks like misnomer; is way to update dyanmic properties
          #below updates db
          @obj_static_properties.update({x => val})    
          #TBD: put in write thru cache pattern; where rather than set cache; blow it away
          set_cached_input_value(@id,x,val)
        end

    private

      def get_from_cache_then_db_and_set_cache(x)
        ret = get_cached_input_value(@id,x)
        return ret if ret
        obj_current = Object.get_object(@id_handle)
        set_cached_input_value(@id,x,obj_current[x])
      end

      def set_cached_input_value(object_id,type,value)
          MemoryCache.set(cache_key(object_id,type),value)
          value
      end

      def get_cached_input_value(object_id,type)
        MemoryCache.get(cache_key(object_id,type))
      end

      def cache_key(object_id,type)
        type.to_s + ":" + object_id.to_s
      end
    end
    end
  end
end
=end

#TBD: should we make hashes like sap and sap_config HashObjects?
module XYZ
  class DerivedValueFunction
    class << self
      def sap_from_config_and_ip(ip_addr,sap_config)
       #TBD: stub; ignores config constraints on sap_config
       return nil if ip_addr.nil? or sap_config.nil?
       port = sap_config[:network] ? sap_config[:network][:port] : nil
       return nil if port.nil?
       {
          :network => {
            :port => port,
            :addresses => [ip_addr]
          }
       }
      end
      
      def sap_ref_from_sap(sap)
        return nil if sap.nil?
        #TBD: stubbed to only handle limited cases
        raise ErrorNotImplemented.new("sap to sap ref function where not type 'network'") unless sap[:network]
        raise Error.new("network sap missing port number") unless sap[:network][:port]
        raise Error.new("network sap missing addresses") unless sap[:network][:addresses]
        raise ErrorNotImplemented.new("saps with multiple IP addresses") unless sap[:network][:addresses].size == 1
        {:network => {
           :port => sap[:network][:port],
           :address => sap[:network][:addresses][0]
          }
        }
      end
    end
  end
end