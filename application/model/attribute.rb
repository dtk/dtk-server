module XYZ
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    def self.up()
      external_ref_column_defs()
      column :value_asserted, :json
      column :value_derived, :json
      column :value_actual, :json
      column :is_settable, :boolean, :default => true
      column :needs_validation, :boolean, :default => false #indicates whether when action executed to set attribute validation is needed before can set actual to desired value
      column :function, :json
      #TBD: may remove  :propagation_type
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
      #TODO: may rename attribute_value to desired_value
      virtual_column :attribute_value

      #Boolean that indicates whether there is a executable script/recipe associated with the attribute
      virtual_column :executable?, :hidden => true
      virtual_column :unknown_in_attribute_value , :hidden => true
      virtual_column :id_info_uri, :hidden => true, :dependencies =>
        [
         {   
           :model_name => :id_info,
           :join_cond=>{:relation_id => :attribute__id},
           :cols=>[:relation_id,:uri]
         }
        ]
      #TODO: now that have uri; may end of life teh two below
      virtual_column :base_objects_node_group, :hidden => true, :dependencies => 
        [
         {
           :model_name => :component,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_group_id]
         },
         {
           :model_name => :node_group,
           :join_cond=>{:id=> :component__node_node_group_id},
           :cols=>[:id, :display_name]
         }

        ]
      virtual_column :base_objects_node, :hidden => true, :dependencies => 
        [
         {
           :model_name => :component,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_id]
         },
         {
           :model_name => :node,
           :join_cond=>{:id=> :component__node_node_id},
           :cols=>[:id, :display_name]
         }

        ]
      many_to_one :component, :node
    end
    ### virtual column defs
    def id_info_uri()
      (self[:id_info]||{})[:uri]
    end
    #######################
    ### object procssing and access functions

    def self.update_from_hash_assignments(id_handle,hash_assigns,opts={})
      Model.update_from_hash_assignments(id_handle,hash_assigns,opts)
      #TODO: should this functionality below be called from within Attribute.update_from_hash_assignments or instead be called
      # from ahigher level fn?
      #if there is an actual change then set up actions to make the change; check whetehr there is an actual change is by 
      # comparing asserted value to attribute_actual; actual change is if attribute_actual is not null (meaning it has been set) and 
      #different from changed_value 
      changed_value = hash_assigns[:value_asserted] #TODO: check whether actual change
      return nil if changed_value.nil?

      #TODO any more efficient way to get action_parent_idh and parent_idh info
      action_parent_idh = id_handle.get_top_container_id_handle(:datacenter)
      return nil unless action_parent_idh #this would happend if top container is not a datacenter TODO: see if this should be "trapped" at higher level
      base_object = get_base_object(id_handle,:node_group)
      new_item_hash = {
        :new_item => id_handle,
        :parent => action_parent_idh
      }
      new_item_hash.merge!(:base_object => base_object) if base_object
      action_id_handle = Action.create_pending_change_item(new_item_hash)
      propagate_changes([AttributeChange.new(id_handle,changed_value,action_id_handle)]) if action_id_handle
    end

    def self.get_base_object(attr_id_handle,base_model_name)
      base_object_vc = "base_objects_#{base_model_name}".to_sym
      fs = FieldSet.opt([:id,:component_component_id,base_object_vc])
      base_object_info = get_objects(attr_id_handle.createMH,{:id => attr_id_handle.get_id()},fs).first
      return nil unless base_object_info
      cmp_display_name = (base_object_info[:component]||{})[:display_name]
      ng_display_name = (base_object_info[base_model_name]||{})[:display_name]
      return nil unless cmp_display_name and ng_display_name
      {:component => {:display_name => cmp_display_name}, base_model_name => {:display_name => ng_display_name}}
    end

    def self.get_base_objects_with_index(attr_model_handle,attr_id_list,base_model_name)
      return Array.new if attr_id_list.empty?
      base_object_vc = "base_objects_#{base_model_name}".to_sym
      wc = SQL.or(*attr_id_list.map{|id|{:id => id}})
      fs = FieldSet.opt([:id,:component_component_id,base_object_vc])
      base_objects_info = get_objects(attr_model_handle,wc,fs)
      return nil unless base_objects_info
       base_objects_info.inject({}) do |h,row|
        cmp_display_name = (row[:component]||{})[:display_name]
        ng_display_name = (row[:node]||{})[:display_name]
        next unless cmp_display_name and ng_display_name
        h.merge(row[:id] => {:component => {:display_name => cmp_display_name}, :node => {:display_name => ng_display_name}})
      end
    end

   private
    ###### helper fns
    def self.propagate_changes(attr_changes) 
      new_changes = AttributeLink.propagate_over_dir_conn_equality_links(attr_changes)
    end



    ##TODO: need to go over each one below to see what we still should use

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
