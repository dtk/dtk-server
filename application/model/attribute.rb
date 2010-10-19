module XYZ
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    class << self
      def up()
        external_ref_column_defs()
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
        column :port_type, :varchar, :size => 10 # null means no port; otherwise "input", "output", or "either"
        virtual_column :attribute_value

        #Boolean that indicates whether there is a executable script/recipe associated with the attribute
        virtual_column :executable?, :hidden => true
        virtual_column :unknown_in_attribute_value , :hidden => true

        #if component attribute then hash with component and node(s) associated with it 
        #TODO remove or rewrite
      #  virtual_column :assoc_components_on_nodes
        many_to_one :component, :node
      end
    end
    ### virtual column defs
    def member_id_list()
      (self[:node]||[]).map{|n|n[:id]}
    end
    #######################
    ### object procssing and access functions

    def self.update_from_hash_assignments(id_handle,hash_assigns,opts={})
      Model.update_from_hash_assignments(id_handle,hash_assigns,opts)
      changed_values = hash_assigns #TODO: stub to check if actual changes (in contrast to hahs_assignment that sets to same value
      return nil if changed_values.empty?
      pending_item_parent_idh = id_handle.get_top_container_id_handle(:datacenter)
      pending_id_handle = PendingChangeItem.create_item(id_handle,pending_item_parent_idh)
      propagate_changes([AttributeChange.new(id_handle,changed_values,pending_id_handle)]) if pending_id_handle
    end

    def self.propagate_changes(attr_changes) 
      new_changes = AttributeLink.propagate_over_directly_conn_links(attr_changes)
    end


    ##TODO: need to go over each one below to see what we still should use

    ###### helper fns
    def check_and_set_derived_relation!()
      ingress_objects = Model.get_objects(ModelHandle.new(id_handle[:c],:attribute_link),:output_id => self[:id])
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
      self[:external_ref].nil? ? false : true
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
  end
end


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
