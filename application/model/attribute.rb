require File.expand_path('model',  File.dirname(__FILE__))

module XYZ
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    class << self
      def up()
        #TBD: first stage of recagctoring (combing attr and attr def); next is going all attrs to see which ones are needed or could be generalized
        column :value_asserted, :json
        column :value_derived, :json
        column :function, :json
        column :propagation_type, :varchar, :size => 20, :default => "immediate" #whether a propagated new value should be immediately set or whether it needs to go through approval, etc
        column :required, :boolean #whether required for this attribute to have a value inorder to execute actions for parent component; TBD: may be indexed by action

        #TBD: do we want to factor output vars out and treat differently
        column :output_variable, :boolean # set to true if as a result of recipe execution var gets computed

        #TODO: may unify the fields below and treat them all as types of constraints, which could be intersected, unioned, etc
        column :data_type, :varchar, :size => 25
        #TBD: whether to explicitly have an array or put this in data type or seamntic_type
        column :is_array, :boolean, :default => false
        column :semantic_type, :json
        column :constraints, :varchar

        #TODO this probably does not belond here column :hidden, :boolean, :default => false
        column :port_type, :varchar, :size => 10 # null means no port; otherwise input or output
        column :external_attr_ref, :varchar
        virtual_column :attribute_value 

        #Boolean that indicates whether there is a executable script/recipe associated with the attribute
        virtual_column :executable?, :hidden => true
        virtual_column :unknown_in_attribute_value , :hidden => true

        #if component attribute then hash with component and node(s) associated with it 
        virtual_column :assoc_components_on_nodes, :dependencies => [:component]  
        many_to_one :component, :node
      end
    end

    ###### helper fns
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

    def unknown_in_attribute_value()
      attr_value = attribute_value()
      return true if attr_value.nil?
      return nil unless self[:is_array]
      return nil unless attr_value.kind_of?(Array) #TBD: this should be error      
      attr_value.each{|v| return true if v.nil?}
      return nil
    end

    def executable?()
      self[:external_attr_ref].nil? ? false : true
    end

    def assoc_components_on_nodes()
      parent_obj = get_parent_object()	
      return [] if parent_obj.nil?
      case parent_obj.relation_type
        when :node
          Array.new
        when :component
          parent_obj.get_objects_associated_nodes().map do |n|
            {:node => n, :component => parent_obj}
          end
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
